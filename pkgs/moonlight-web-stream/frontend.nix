# Web frontend of moonlight-web-stream (webpack + WASM bindings).
#
# The upstream build runs `npm run prebuild`, which checks out
# moonlight-common-rust with git and then invokes ubrn. That cannot run in the
# Nix sandbox, so the checkout is supplied as a regular source input, both
# cargo vendor trees are assembled locally, and only the final webpack step is
# delegated to the npm build hook.
{
  lib,
  buildNpmPackage,
  nodejs_26,
  rustPlatform,
  cargo,
  rustc,
  git,
  lld,
  wasm-bindgen,
  ubrn,
  version,
  src,
  moonlightCommon,
}:
let
  rootVendor = rustPlatform.importCargoLock { lockFile = ./Cargo.lock; };
  wasmVendor = rustPlatform.importCargoLock { lockFile = ./wasm-Cargo.lock; };
  commonVendor = rustPlatform.importCargoLock { lockFile = ./common-Cargo.lock; };
in
buildNpmPackage {
  pname = "moonlight-web-stream-frontend";
  inherit version src;
  nodejs = nodejs_26;

  npmDepsHash = "sha256-FkODIM9qT01nUOdXXYhb9Ej11WQIziu8HX9KtgFf4P4=";

  env.CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_LINKER = "${lld}/bin/wasm-ld";

  nativeBuildInputs = [
    cargo
    rustc
    git
    lld
    wasm-bindgen
    ubrn
  ];

  patches = [
    ./patches/0001-streaming-experiments.patch
    ./patches/0002-jis-keyboard.patch
    ./patches/0003-host-settings.patch
    ./patches/0006-ts-symbol-template.patch
  ];

  preBuild = ''
    mkdir -p rust_modules/moonlight-common-rust
    cp -a ${moonlightCommon}/. rust_modules/moonlight-common-rust/
    chmod -R u+w rust_modules
    (
      cd rust_modules/moonlight-common-rust
      git init -q
      git apply --ignore-whitespace \
        ${./patches/0004-moonlight-common-av1.patch} \
        ${./patches/0005-moonlight-common-stall-timeout.patch}
    )

    # Merge the cargo vendor trees of the server workspace and the generated
    # WASM crate; `cargo vendor` output is a directory of per-crate symlinks.
    mkdir -p vendor cargo-home
    for dir in ${rootVendor} ${wasmVendor} ${commonVendor}; do
      for entry in "$dir"/*; do
        name=$(basename "$entry")
        case "$name" in
          Cargo.lock | .cargo) continue ;;
        esac
        if [ ! -e "vendor/$name" ]; then
          ln -s "$entry" "vendor/$name"
        fi
      done
    done
    cat > cargo-home/config <<EOF
    [source.crates-io]
    replace-with = "vendored-sources"
    [source.vendored-sources]
    directory = "$PWD/vendor"
    EOF
    export CARGO_HOME="$PWD/cargo-home"
    export CARGO_NET_OFFLINE="true"

    # web/api_bindings.ts (ts-rs) and web/uniffi/** (ubrn + wasm-bindgen).
    cargo test export_bindings
    mkdir -p rust_modules/wasm
    cp ${./wasm-Cargo.lock} rust_modules/wasm/Cargo.lock
    ubrn build web
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r dist/. $out/
    runHook postInstall
  '';

  # The upstream `npm run build` script also runs the prebuild steps (cargo
  # bindings + ubrn); they are executed in preBuild above, so only webpack is
  # left here. Overriding buildPhase bypasses npmBuildHook entirely.
  dontNpmBuild = true;
  buildPhase = ''
    runHook preBuild
    npx webpack --mode=production
  '';

  meta = {
    description = "Web frontend for moonlight-web-stream";
    license = lib.licenses.gpl3Plus;
  };
}
