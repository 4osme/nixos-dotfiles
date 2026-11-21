# Small user services of the session: gnome-keyring (the Fedora hyprland.lua
# started gnome-keyring-daemon by hand) and ydotoold (the Fedora image enabled
# the packaged ydotool user unit). The polkit agent is Dux Shell's built-in
# one (hyprpolkitagent removed to avoid two agents competing).
{ pkgs, ... }:
{
  services.gnome-keyring.enable = true;

  systemd.user.services.ydotoold = {
    Unit = {
      Description = "ydotoold - ydotoold daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.ydotool}/bin/ydotoold";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
