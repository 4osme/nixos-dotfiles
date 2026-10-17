# HyprBind v0.1.4 (ry2x/HyprBind) — the keybind viewer the source image
# installed from the upstream Arch package; built from source here.
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  libxkbcommon,
  wayland,
  libGL,
}:
rustPlatform.buildRustPackage rec {
  pname = "hyprbind";
  version = "0.1.4";

  src = fetchFromGitHub {
    owner = "ry2x";
    repo = "HyprBind";
    rev = "v${version}";
    hash = "sha256-+1w2Ap6mfHPZ0c5N2dXdo9Zf+Y6XiI9+6FZgdKnUwnM=";
  };

  cargoHash = "sha256-b8bJNpthsWbIq3D5NoVbi3lPBqRak06mJyy7UUQYIwg=";

  nativeBuildInputs = [ pkg-config ];

  # eframe/egui with the glow backend: links xkbcommon + wayland, dlopens GL.
  buildInputs = [
    libxkbcommon
    wayland
    libGL
  ];

  postInstall = ''
    # The crate builds $out/bin/HyprBind; the desktop entry, the keybinding in
    # hyprland.lua and the Fedora package all use the lowercase name.
    mv $out/bin/HyprBind $out/bin/hyprbind

    install -Dm644 hyprbind.desktop $out/share/applications/hyprbind.desktop
    install -Dm644 assets/logo_hyprbind.png $out/share/pixmaps/hyprbind.png
    install -Dm644 LICENSE-MIT $out/share/licenses/hyprbind/LICENSE-MIT
    install -Dm644 LICENSE-OFL $out/share/licenses/hyprbind/LICENSE-OFL-1.1
  '';

  meta = {
    description = "A GUI to display Hyprland keybindings";
    homepage = "https://github.com/ry2x/HyprBind";
    license = with lib.licenses; [
      mit
      ofl
    ];
    mainProgram = "hyprbind";
    platforms = lib.platforms.linux;
  };
}
