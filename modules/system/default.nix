# Common system layer of every NixOS machine: OS basics, session services,
# distrobox/flatpak foundations and the desktop plumbing.
{ lib, ... }:
{
  imports = [
    ./boot.nix
    ./kernel.nix
    ./nix.nix
    ./networking.nix
    ./locale.nix
    ./audio.nix
    ./users.nix
    ./sddm.nix
    ./dconf.nix
    ./fonts.nix
    ./portals.nix
    ./flatpak.nix
    ./distrobox.nix
    ./security.nix
    ./packages.nix
    ./hardware.nix
  ];

  # The custom packages (hyprbind, mozkey, …).
  nixpkgs.overlays = [ (import ../../overlays) ];

  # TODO(manual): bump once at install; never change afterwards (see the
  # NixOS manual / anti-patterns).
  system.stateVersion = "26.05";
}
