# Sunshine as a per-user service (main-desktop only; imported conditionally
# from home/default.nix). It needs the session's Wayland/DRM access and reads
# ~/.config/sunshine, exactly like the manually started Fedora setup.
# The display profile switching (host.lua) talks to its runtime markers in
# $XDG_RUNTIME_DIR/sunshine-hypr-display via ~/.config/sunshine/hypr-stream-display.py.
#
# Disable by removing the import in home/default.nix if the host should not
# autostart Sunshine.
{ pkgs, ... }:
{
  systemd.user.services.sunshine = {
    Unit = {
      Description = "Sunshine game streaming host (JIS build)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.sunshine}/bin/sunshine";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
