# moonlight-web-stream (browser Moonlight client) — main-desktop only.
# The package is built from upstream + patches in pkgs/moonlight-web-stream.
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.moonlight-web-stream ];

  # The web UI listens on 0.0.0.0:8080 by default. The Cloudflare tunnel
  # reaches it over loopback; this also allows direct access on the LAN.
  networking.firewall.allowedTCPPorts = [ 8080 ];
}
