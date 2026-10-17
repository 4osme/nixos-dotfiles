# Per-user HyprTomic desktop: the package set the hyprtomic-gui container
# used to carry, the dotfile sync tool and the small user services.
{
  pkgs,
  inputs,
  hostName,
  lib,
  ...
}:
{
  imports = [
    ./packages.nix
    ./zsh.nix
    ./services.nix
    ./dotfiles.nix
    ./theme.nix
  ];

  home.username = "underdone";
  home.homeDirectory = "/home/underdone";
  home.stateVersion = "26.05";

  # Read by systemd user services (the compositor sets the same values for
  # the graphical session in hyprland.lua).
  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt6ct";
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "36";
  };
}
