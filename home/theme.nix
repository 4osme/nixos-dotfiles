# Theme defaults in the user dconf database (Home Manager managed): the same
# values the Fedora image compiled into its system db. Static now — the icon /
# cursor / theme choices no longer change at runtime (apply-icon-theme.sh is
# gone with the theme switcher).
{ lib, ... }:
let
  interface = {
    color-scheme = "prefer-dark";
    gtk-theme = "Adwaita";
    icon-theme = "Tela-circle-dark";
    font-name = "Noto Sans Light 9";
    cursor-theme = "Bibata-Modern-Classic";
    cursor-size = lib.gvariant.mkInt32 36;
  };
in
{
  dconf.settings = {
    "org/gnome/desktop/interface" = interface;
    "org/cinnamon/desktop/interface" = interface;
  };
}
