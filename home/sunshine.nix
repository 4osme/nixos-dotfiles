# Sunshine (game streaming host) and the Cloudflare tunnel, both manual and
# main-desktop only (imported conditionally from home/default.nix).
#
# Nothing is enabled at login on purpose: start a streaming session from a
# terminal/SSH with
#
#   sunshine-session start --tunnel   # HEADLESS-1 FullHD + Sunshine + tunnel
#
# and stop it with
#
#   sunshine-session stop --tunnel
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

  # The tunnel is defined but never enabled. TUNNEL_TOKEN must be supplied by
  # the unmanaged (mode 0600) file; see README.md.
  systemd.user.services.cloudflared-tunnel = {
    Unit = {
      Description = "cloudflared tunnel (manual start)";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      EnvironmentFile = "%h/.config/cloudflared/tunnel.env";
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel run --token \${TUNNEL_TOKEN}";
      Restart = "on-failure";
      RestartSec = 5;
    };
    # No Install section on purpose: `systemctl --user start cloudflared-tunnel`.
  };
}
