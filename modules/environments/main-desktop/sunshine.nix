# Sunshine (game streaming host) with the JIS keyboard patches: the JIS build
# from ../sunshine-nix, vendored under pkgs/sunshine/ and wired into the
# overlay (overlays/default.nix overrides pkgs.sunshine). The patches target
# Sunshine v2026.914.233613, the version in nixpkgs 26.05.
#
# The per-user unit that starts it lives in home/sunshine.nix (imported for
# main-desktop only). It is intentionally not enabled at login: start it with
# `sunshine-session start` together with the tunnel (cloudflared-tunnel).
{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.sunshine
    pkgs.cloudflared
  ];
}
