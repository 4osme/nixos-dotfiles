# wasm-bindgen-cli pinned to the exact version used by
# moonlight-web-stream's Cargo.wasm.toml (0.2.128). nixpkgs ships 0.2.129,
# and wasm-bindgen refuses to process a module built with a different version.
{
  lib,
  rustPlatform,
  fetchCrate,
  pkg-config,
}:
rustPlatform.buildRustPackage {
  pname = "wasm-bindgen-cli";
  version = "0.2.128";

  src = fetchCrate {
    pname = "wasm-bindgen-cli";
    version = "0.2.128";
    hash = "sha256-a7lcXJnnZkYReja+iUO7NqqrWyv3toxnUgQb8s4IS5s=";
  };

  cargoLock.lockFile = ./wasm-bindgen-Cargo.lock;

  nativeBuildInputs = [ pkg-config ];

  doCheck = false;

  meta = {
    description = "CLI for wasm-bindgen (pinned 0.2.128)";
    license = with lib.licenses; [
      asl20
      mit
    ];
    mainProgram = "wasm-bindgen";
  };
}
