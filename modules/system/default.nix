# Common system layer of every HyprTomic NixOS machine: OS basics, session
# services, KVM/distrobox/flatpak foundations and the desktop plumbing that the
# fedora-hyprtomic host image shipped.
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
    ./virt.nix
    ./security.nix
    ./packages.nix
    ./hardware.nix
  ];

  # The custom packages (hyprbind, quickshell patch, mozkey, Vypr, …).
  nixpkgs.overlays = [ (import ../../overlays) ];

  # TODO(manual): bump once at install; never change afterwards (see the
  # NixOS manual / anti-patterns).
  system.stateVersion = "26.05";
}
