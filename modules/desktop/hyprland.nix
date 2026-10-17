# The Hyprland session (the compositor, uwsm, portals and lock-screen
# service). The user configuration (hyprland.lua, hyprlock.conf, …) is
# delivered by the config sync (files/home → ~/.config), exactly like the
# source image's /etc/skel.
{ pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    # `uwsm app` is how the quickshell launcher starts applications
    # (~/.config/quickshell/ii/modules/launcher/Launcher.qml).
    withUWSM = true;
    xwayland.enable = true;
  };

  # Wayland for Chromium/Electron (Chrome, Vesktop, …).
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
