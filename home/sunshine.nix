# Sunshine (game streaming host), manual and main-desktop only
# (imported conditionally from home/default.nix).
#
# Nothing is enabled at login on purpose: start a streaming session from a
# terminal/SSH with
#
#   sunshine-session start   # HEADLESS-1 FullHD + Sunshine
#
# and stop it with
#
#   sunshine-session stop
#
# The display profile lives in files/home-main-desktop/.config/hypr/host.lua;
# sunshine-session creates the virtual output and the marker.
{ pkgs, ... }:
{
  # ~/.local/bin/sunshine-session (files/home-main-desktop).
  home.sessionPath = [ "$HOME/.local/bin" ];

  systemd.user.services.sunshine = {
    Unit = {
      Description = "Sunshine game streaming host (JIS build, manual start)";
      # PartOf only propagates stop/restart; it does not start the unit.
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.sunshine}/bin/sunshine";
      Restart = "on-failure";
    };
    # No Install.WantedBy: `sunshine-session start` (systemctl --user start)
    # starts it on demand.
  };

}
