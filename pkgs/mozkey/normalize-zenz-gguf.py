#!/usr/bin/env python3
"""Normalise the Zenz GGUF model for an unmodified llama.cpp.

The published Zenz v3.2 GGUF names a private pre-tokenizer
(``gpt2-small-japanese-char``) and carries wrong special token ids, so a
stock llama.cpp refuses to load it.  This script rewrites the GGUF metadata
only:

* ``tokenizer.ggml.pre``            -> ``gpt-2``
* ``tokenizer.ggml.bos_token_id``   -> the ``<s>`` vocabulary position
* ``tokenizer.ggml.eos_token_id``   -> the ``</s>`` vocabulary position
* ``tokenizer.ggml.unknown_token_id`` -> the ``[UNK]`` vocabulary position

Tensor descriptors and the tensor payload are copied byte for byte.

The idea follows the Mozkey IbG project (kazormia296/mozkey-ibg), which
ships the same normalisation for its Linux releases.
"""

from __future__ import annotations

import argparse
import hashlib
import struct
import sys
from pathlib import Path

MAGIC = b"GGUF"
VERSION = 3
DEFAULT_ALIGNMENT = 32

KEY_PRE = b"tokenizer.ggml.pre"
KEY_TOKENS = b"tokenizer.ggml.tokens"
KEY_BOS = b"tokenizer.ggml.bos_token_id"
KEY_EOS = b"tokenizer.ggml.eos_token_id"
KEY_UNK = b"tokenizer.ggml.unknown_token_id"
KEY_ALIGNMENT = b"general.alignment"

CUSTOM_PRETOKENIZER = b"gpt2-small-japanese-char"
UPSTREAM_PRETOKENIZER = b"gpt-2"

TYPE_UINT8 = 0
TYPE_INT8 = 1
TYPE_UINT16 = 2
TYPE_INT16 = 3
TYPE_UINT32 = 4
TYPE_INT32 = 5
TYPE_FLOAT32 = 6
TYPE_BOOL = 7
TYPE_STRING = 8
TYPE_ARRAY = 9
TYPE_UINT64 = 10
TYPE_INT64 = 11
TYPE_FLOAT64 = 12

SCALAR_SIZES = {
    TYPE_UINT8: 1,
    TYPE_INT8: 1,
    TYPE_UINT16: 2,
    TYPE_INT16: 2,
    TYPE_UINT32: 4,
    TYPE_INT32: 4,
    TYPE_FLOAT32: 4,
    TYPE_BOOL: 1,
    TYPE_UINT64: 8,
    TYPE_INT64: 8,
    TYPE_FLOAT64: 8,
}


class GgufError(ValueError):
    """The input is not a GGUF file this script understands."""


class Reader:
    def __init__(self, data: bytes) -> None:
        self.data = data
        self.pos = 0

    def take(self, size: int) -> bytes:
        if size < 0 or self.pos + size > len(self.data):
            raise GgufError("truncated GGUF")
        chunk = self.data[self.pos : self.pos + size]
        self.pos += size
        return chunk

    def u32(self) -> int:
        return struct.unpack("<I", self.take(4))[0]

    def u64(self) -> int:
        return struct.unpack("<Q", self.take(8))[0]

    def string(self) -> bytes:
        return self.take(self.u64())

    def value(self, type_tag: int) -> object:
        if type_tag in SCALAR_SIZES:
            raw = self.take(SCALAR_SIZES[type_tag])
            if type_tag == TYPE_UINT32:
                return struct.unpack("<I", raw)[0]
            if type_tag == TYPE_BOOL:
                return raw != b"\x00"
            return None
        if type_tag == TYPE_STRING:
            return self.string()
        if type_tag != TYPE_ARRAY:
            raise GgufError(f"unsupported GGUF value type {type_tag}")
        element_type = self.u32()
        if element_type == TYPE_ARRAY or element_type not in SCALAR_SIZES and element_type != TYPE_STRING:
            raise GgufError("unsupported GGUF array element type")
        count = self.u64()
        if element_type == TYPE_STRING:
            return [self.string() for _ in range(count)]
        return [self.value(element_type) for _ in range(count)]


def encode_string(value: bytes) -> bytes:
    return struct.pack("<Q", len(value)) + value


def encode_entry(key: bytes, type_tag: int, value: bytes | int) -> bytes:
    out = bytearray(encode_string(key))
    out += struct.pack("<I", type_tag)
    if type_tag == TYPE_STRING:
        out += encode_string(value)  # type: ignore[arg-type]
    elif type_tag == TYPE_UINT32:
        out += struct.pack("<I", value)  # type: ignore[arg-type]
    else:
        raise GgufError("unsupported normalised value type")
    return bytes(out)


def round_up(value: int, alignment: int) -> int:
    return (value + alignment - 1) // alignment * alignment


def normalise(data: bytes) -> bytes:
    reader = Reader(data)
    if reader.take(4) != MAGIC:
        raise GgufError("not a GGUF file")
    version = reader.u32()
    if version != VERSION:
        raise GgufError(f"unsupported GGUF version {version}")
    tensor_count = reader.u64()
    kv_count = reader.u64()

    entries: list[tuple[bytes, int, bytes, object]] = []
    tokens: list[bytes] = []
    for _ in range(kv_count):
        start = reader.pos
        key = reader.string()
        type_tag = reader.u32()
        value = reader.value(type_tag)
        entries.append((key, type_tag, data[start : reader.pos], value))
        if key == KEY_TOKENS:
            tokens = value  # type: ignore[assignment]

    special = {}
    for token in (b"<s>", b"</s>", b"[UNK]"):
        matches = [index for index, item in enumerate(tokens) if item == token]
        if len(matches) != 1:
            raise GgufError(f"special token {token!r} is missing or duplicated")
        special[token] = matches[0]

    replacements = {
        KEY_PRE: (TYPE_STRING, UPSTREAM_PRETOKENIZER),
        KEY_BOS: (TYPE_UINT32, special[b"<s>"]),
        KEY_EOS: (TYPE_UINT32, special[b"</s>"]),
        KEY_UNK: (TYPE_UINT32, special[b"[UNK]"]),
    }

    alignment = DEFAULT_ALIGNMENT
    for key, type_tag, _, value in entries:
        if key == KEY_ALIGNMENT and type_tag == TYPE_UINT32:
            alignment = int(value)  # type: ignore[arg-type]

    out = bytearray(MAGIC)
    out += struct.pack("<IQQ", version, tensor_count, kv_count + (0 if KEY_UNK in replacements and any(key == KEY_UNK for key, _, _, _ in entries) else 1))
    seen = set()
    for key, type_tag, raw, _ in entries:
        seen.add(key)
        replacement = replacements.get(key)
        if replacement is None:
            out += raw
        else:
            out += encode_entry(key, *replacement)
    if KEY_UNK not in seen:
        out += encode_entry(KEY_UNK, *replacements[KEY_UNK])

    tensor_info_start = reader.pos
    for _ in range(tensor_count):
        reader.string()
        dimensions = reader.u32()
        reader.take(dimensions * 8)
        reader.take(4)
        reader.take(8)
    tensor_info_end = reader.pos
    out += data[tensor_info_start:tensor_info_end]

    out += b"\x00" * (round_up(len(out), alignment) - len(out))
    out += data[round_up(tensor_info_end, alignment) :]
    return bytes(out)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("target", type=Path)
    args = parser.parse_args()

    data = args.source.read_bytes()
    result = normalise(data)
    args.target.write_bytes(result)
    print(
        f"normalised {args.source} -> {args.target} "
        f"(sha256 {hashlib.sha256(result).hexdigest()})"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
