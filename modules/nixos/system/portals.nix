# XDG portals: GTK + GNOME background (xdg-desktop-portal-gnome provides the
# Background interface for Flatpak autostart toggles). The file chooser stays
# GTK since xdg-desktop-portal-kde is not installed.
{ pkgs, ... }:
{
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
    xdgOpenUsePortal = true;
    config = {
      hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.Background" = [ "gnome" ];
      };
    };
  };
}
