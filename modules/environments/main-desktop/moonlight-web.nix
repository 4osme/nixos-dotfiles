# moonlight-web-stream (browser Moonlight client) — main-desktop only.
# The package is built from upstream + patches in pkgs/moonlight-web-stream.
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.moonlight-web-stream ];

  # The tunnel reaches the web UI over loopback; do not expose port 8080
  # through the host firewall.
}
