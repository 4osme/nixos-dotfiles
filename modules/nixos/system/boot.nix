# systemd-boot on the reference disk layout: one FAT ESP mounted at /boot
# (kernels + initrd live there; there is no separate XBOOTLDR partition, see
# hosts/main-desktop/storage.nix).
{ lib, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.systemd-boot.editor = false;
  boot.loader.timeout = 3;

  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "udev.log_level=3"
  ];

  # The source host inits ram → swap early; zram is filled before the disk
  # swap (priority 10 here vs 5 on /dev/disk/by-label/swapart in the host
  # storage module).
  zramSwap.enable = true;
  zramSwap.priority = 10;
}
