# Distrobox containers use Podman; the desktop shell runs natively.
{ pkgs, ... }:
{
  virtualisation.podman.enable = true;

  environment.systemPackages = [ pkgs.distrobox ];
}
