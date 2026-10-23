# uniffi-bindgen-react-native (ubrn) from the upstream source. It is a build
# tool for moonlight-web-stream's WASM/TypeScript bindings; it is not installed
# on the system.
#
# ubrn locates its runtime crate through CARGO_MANIFEST_DIR at compile time.
# Nix builds in a temporary /build directory, so replace that path with the
# immutable source path in the store; the resulting binary then keeps the
# runtime crate available as a runtime reference.
{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
let
  version = "0.31.0-3";
  src = fetchFromGitHub {
    owner = "jhugman";
    repo = "uniffi-bindgen-react-native";
    rev = version;
    hash = "sha256-GZmRRGbMHukN9o6iOeBmdz1KWCtWqHIjuR0RWEQR0ec=";
  };
in
rustPlatform.buildRustPackage {
  pname = "uniffi-bindgen-react-native";
  inherit version src;

  cargoLock.lockFile = ./ubrn-Cargo.lock;

  cargoBuildFlags = [
    "-p"
    "uniffi-bindgen-react-native"
  ];

  postPatch = ''
    substituteInPlace crates/ubrn_cli/src/wasm/codegen.rs \
      --replace 'env!("CARGO_MANIFEST_DIR")' '"${src}/crates/ubrn_cli"'
  '';

  postInstall = ''
    ln -s $out/bin/uniffi-bindgen-react-native $out/bin/ubrn
  '';

  doCheck = false;

  meta = {
    description = "UniFFI bindings generator for React Native/Web (ubrn)";
    license = lib.licenses.mpl20;
    mainProgram = "ubrn";
  };
}
