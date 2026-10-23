# Per-user HyprTomic desktop: the package set the hyprtomic-gui container
# used to carry, Home Manager-managed dotfiles and the small user services.
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
  ]
  ++ lib.optional (hostName == "main-desktop") ./sunshine.nix
  ++ lib.optional (hostName == "main-desktop") ./moonlight-web.nix;

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

  # sigma-file-manager is the default handler for directories
  # (AGENTS.md: nemo replaced by sigma-file-manager).
  xdg.mimeApps = {
    enable = true;
    defaultApplications."inode/directory" = "sigma-file-manager.desktop";
  };
}
