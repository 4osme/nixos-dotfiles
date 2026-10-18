# The AGENTS.md tool list + the GUI components the hyprtomic-gui container
# carried (quickshell shell, hyprbind, hypremoji, clipse, …). Qt/Kvantum
# theming stays on the shipped dotfiles (apply-theme.sh edits the same files),
# so do not enable the Home Manager qt/gtk modules here.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # --- tools (AGENTS.md) ---
    fastfetch
    git
    gh # github-cli
    tea # gitea CLI
    vscode
    vesktop
    mission-center
    bitwarden-desktop
    google-chrome
    easyeffects
    sshfs # = sshfs-fuse
    neovim
    ghostty
    zsh

    # --- desktop shell / GUI components (hyprtomic-gui) ---
    quickshell
    hyprbind
    hypremoji
    resolve-icons # GTK icon resolver wrapper for the quickshell launcher
    clipse
    rofi
    nwg-displays
    haruna
    sigma-file-manager # default file manager (nemo dropped, AGENTS.md)
    file-roller
    pavucontrol
    wl-clipboard
    cliphist
    grim
    slurp
    hyprpicker
    hyprsunset
    brightnessctl
    playerctl
    libnotify
    dex
    wtype
    ydotool
    jq
    python3 # ~/.config/sunshine/hypr-stream-display.py (main-desktop)

    # Icon themes / cursors named by the configs (gtk settings.ini, qt6ct,
    # dconf icon-theme).
    papirus-icon-theme
    tela-circle-icon-theme
    bibata-cursors

    # Qt theme tools (the configs in ~/.config/qt{5,6}ct + Kvantum are synced;
    # these are the binaries apply-theme.sh / the settings.ini expect).
    qt6Packages.qt6ct
    libsForQt5.qt5ct
    qt6Packages.qtstyleplugin-kvantum
    libsForQt5.qtstyleplugin-kvantum

    # gsettings/dconf CLI for apply-icon-theme.sh and the shell scripts.
    glib
    dconf
    gsettings-desktop-schemas

    # xdg helpers the session relies on (nemo/xdg-open, mime handlers).
    xdg-utils
    desktop-file-utils
    shared-mime-info
  ];
}
