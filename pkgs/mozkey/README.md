# fcitx5-mozkey

`Masterisk-F/fcitx-mozkey` — a Mozc fork with live conversion and local
Zenz correction — packaged as an Fcitx 5 addon.

The upstream project builds with Bazel and resolves its dependencies through
Bzlmod, so the package drives a Bazel build:

| topic | decision |
|---|---|
| Bzlmod registry | a pinned Bazel Central Registry checkout (`bcrRev`), unpacked in `preConfigure` and passed as `--registry=file://…` |
| external archives | every archive Bazel would download is listed in `bazel-archives.json`, prefetched by Nix and handed over through `--distdir` |
| module graph | `MODULE.bazel.lock` (upstream does not commit one) |
| material design icons | three of them share their file name and can therefore not live in a distdir, they are fetched separately and installed directly |
| Zenz model | the published GGUF names a private pre-tokenizer that llama.cpp rejects, so its metadata is normalised (`normalize-zenz-gguf.py`); the result is byte identical to the model the Mozkey IbG release ships |
| rules_python | patched, see below |

The Bazel build itself never touches the network.

## rules_python

The Python build tools of Mozkey (the dictionary generator, the version
stamp, …) are `py_binary` targets of rules_python.  Their stubs

* start with a `#!/usr/bin/env python3` shebang, and that interpreter does
  not exist in the Nix sandbox, and
* re-execute the standalone CPython of the rules_python toolchain, whose
  dynamic loader is not available either.

The package therefore overrides the rules_python module with a patched copy
that uses the Python interpreter of the build for both.

## Updating

* `rev` — the upstream revision.  There is no tag that contains the Fcitx 5
  addon yet, so a commit is pinned.
* `bcrRev` — the Bazel Central Registry commit.
* `bazel-archives.json` — the archives of the module graph.  Regenerate it
  with `bazel mod graph` (the module list), the Bazel Central Registry
  (`source.json` of every module gives URL and checksum) and
  `src/MODULE.bazel` (the data files Mozkey fetches itself).
* `MODULE.bazel.lock` — the resolved module graph, `bazel mod graph` plus
  the recorded extension results.
