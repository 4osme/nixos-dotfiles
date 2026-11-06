{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    # --- tools (AGENTS.md) ---
    fastfetch
    git
    gh # github-cli
    tea # gitea CLI
    vscode
    vesktop # fallback until the NixOS migration is finished
    inputs.serein.packages.${pkgs.stdenv.hostPlatform.system}.default
    bitwarden-desktop
    google-chrome
    easyeffects
    sshfs # = sshfs-fuse
    neovim
    ghostty
    zsh

    # --- Dux utils (modules are enabled in home/default.nix). dgop backs the
    # DMS system-monitoring widgets via PATH. ---
    inputs.dgop.packages.${pkgs.stdenv.hostPlatform.system}.default

    # --- desktop shell / GUI components ---
    hyprbind
    hypremoji
    rofi # window switcher (Dux Shell has no Hyprland alt-tab)
    satty # screenshot annotation (pipe: `dms screenshot --stdout | satty -f -`)
    adw-gtk3 # Dux Shell "Apply GTK Themes" prerequisite
    nwg-displays
    haruna
    pavucontrol
    wl-clipboard # hypremoji などが使用
    libnotify
    dex
    wtype
    ydotool
    jq
    python3 # ~/.config/sunshine/hypr-stream-display.py (main-desktop)

    # Icon themes / cursors available to Dux Shell icon/cursor theming.
    papirus-icon-theme
    tela-circle-icon-theme
    bibata-cursors

    # Qt theming goes through qt5ct/qt6ct (Dux Shell generates their color
    # files); Kvantum and the old md3-amethyst palettes are gone.
    qt6Packages.qt6ct
    libsForQt5.qt5ct

    # gsettings/dconf CLI used by the session scripts and Dux Shell.
    glib
    dconf
    gsettings-desktop-schemas

    # xdg helpers the session relies on (xdg-open, mime handlers).
    xdg-utils
    desktop-file-utils
    shared-mime-info
  ];
}
