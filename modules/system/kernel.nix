# Every HyprTomic machine runs the same kernel:
# linux-cachyos-bore-lto-x86_64-v3 from xddxdd/nix-cachyos-kernel.
{ pkgs, inputs, ... }:
{
  # `pinned` keeps the kernel (and its ZFS/extra modules) built against the
  # flake's own nixpkgs so the lantian binary cache hits (see nix.nix).
  nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];

  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-x86_64-v3;
}
