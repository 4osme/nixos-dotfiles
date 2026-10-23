# moonlight-web-stream (WebRTC Moonlight client/server) built from upstream
# source plus the local patches kept in ./patches. Only main-desktop enables
# the service; the package is exposed through overlays/default.nix.
#
# The source is pinned to upstream master a27f912 (v3 prerelease) and the
# patches are the JIS keyboard work, the host settings override and the
# streaming/relay experiments from ../moonlight-web-stream. The
# moonlight-common-rust dependency is fetched separately because the upstream
# commit still references it as a git dependency; the patches switch it to a
# local path so the protocol fixes can be applied before the server and WASM
# client are built.
{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  callPackage,
  git,
}:
let
  version = "3.0.0-prerelease.7";

  src = fetchFromGitHub {
    owner = "MrCreativ3001";
    repo = "moonlight-web-stream";
    rev = "a27f9126248fee88cad37fac7ebaec72bf8b2de0";
    hash = "sha256-ECKNosG7wXw0MjilfYJ2u7i3qu3O0IjxXtcAwK6vaUY=";
  };

  moonlightCommon = fetchFromGitHub {
    owner = "MrCreativ3001";
    repo = "moonlight-common-rust";
    rev = "cc7ec8c3b3063742f4941500dcb78650bd0a9b98";
    hash = "sha256-Klily4EOdVknFJB9KDqk2e3q7ndc6Aig0NIhuBmv4Qg=";
  };

  frontend = callPackage ./frontend.nix {
    inherit version src moonlightCommon;
    ubrn = callPackage ./ubrn.nix { };
    wasm-bindgen = callPackage ./wasm-bindgen.nix { };
  };

  server = rustPlatform.buildRustPackage {
    pname = "moonlight-web-stream";
    inherit version src;

    cargoLock.lockFile = ./Cargo.lock;

    nativeBuildInputs = [ git ];

    patches = [
      ./patches/0001-streaming-experiments.patch
      ./patches/0002-jis-keyboard.patch
      ./patches/0003-host-settings.patch
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
    '';

    doCheck = false;

    meta = {
      description = "WebRTC client/server for Sunshine (web server)";
      license = lib.licenses.gpl3Plus;
      mainProgram = "web-server";
    };
  };
in
stdenv.mkDerivation {
  pname = "moonlight-web-stream";
  inherit version;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share/moonlight-web-stream/static
    ln -s ${server}/bin/web-server $out/bin/web-server
    cp -r ${frontend}/. $out/share/moonlight-web-stream/static/
    runHook postInstall
  '';

  meta = {
    description = "Moonlight client in the browser, with the local streaming patches";
    license = lib.licenses.gpl3Plus;
    mainProgram = "web-server";
  };
}
