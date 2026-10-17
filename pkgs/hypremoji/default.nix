# hypremoji v1.3.0 (Musagy/hypremoji) — the emoji picker used by
# `Super+period` and the window rule dev.musagy.hypremoji.
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  gtk4,
  wrapGAppsHook4,
  wl-clipboard,
}:
rustPlatform.buildRustPackage rec {
  pname = "hypremoji";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "Musagy";
    repo = "hypremoji";
    rev = "v${version}";
    hash = "sha256-GFqjPeufG8Vh2nq1155Os7+MfvuGJXsfApImPIyeupM=";
  };

  # Upstream ships no Cargo.lock; the committed one pins the resolution
  # (generated once from this source, then kept in the repository).
  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
  };
  # buildRustPackage validates src/Cargo.lock against the vendored tree, so
  # put the committed lockfile into the source first.
  cargoPatches = [ ./add-Cargo.lock.patch ];

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = [ gtk4 ];

  # The picker copies the selection with wl-copy.
  postFixup = ''
    wrapProgram $out/bin/hypremoji \
      --prefix PATH : ${lib.makeBinPath [ wl-clipboard ]}
  '';

  meta = {
    description = "A modern emoji picker for Hyprland, written in Rust + GTK4";
    homepage = "https://github.com/Musagy/hypremoji";
    license = lib.licenses.isc;
    mainProgram = "hypremoji";
    platforms = lib.platforms.linux;
  };
}
