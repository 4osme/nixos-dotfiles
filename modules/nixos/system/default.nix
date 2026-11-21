# Common system layer of every NixOS machine: OS basics, session services,
# distrobox/flatpak foundations and the desktop plumbing.
{ ... }:
{
  imports = [
    ./boot.nix
    ./kernel.nix
    ./nix.nix
    ./networking.nix
    ./locale.nix
    ./audio.nix
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
  nixpkgs.overlays = [ (import ../../../overlays) ];
}
