# XDG portals (the source install: Gtk + gnome-background, with
# hyprland-portals.conf in skel). xdg-desktop-portal-gnome provides the
# Background interface for Flatpak autostart toggles; the file chooser stays
# GTK (the source skel pointed it at KDE, whose portal is not installed here —
# adjust to taste).
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
