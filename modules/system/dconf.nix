# System-wide dconf defaults (the source host compiled the same values into
# /etc/dconf/db/hyprtomic.d/00-desktop). The user database stays writable, so
# apply-icon-theme.sh keeps working through gsettings at runtime.
{ lib, ... }:
{
  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            gtk-theme = "Adwaita";
            icon-theme = "Papirus-Dark";
            font-name = "Noto Sans Light 9";
            cursor-theme = "Bibata-Modern-Classic";
            cursor-size = lib.gvariant.mkInt32 36;
          };
          "org/cinnamon/desktop/interface" = {
            color-scheme = "prefer-dark";
            gtk-theme = "Adwaita";
            icon-theme = "Papirus-Dark";
            font-name = "Noto Sans Light 9";
            cursor-theme = "Bibata-Modern-Classic";
            cursor-size = lib.gvariant.mkInt32 36;
          };
        };
      }
    ];
  };
}
