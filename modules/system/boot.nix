# systemd-boot on the reference disk layout: 600M ESP (/efi) + 2G XBOOTLDR
# (/boot), replacing the Fedora layout 1:1 (the old /boot role stays on the
# same partition, kernels simply live in XBOOTLDR now).
{ lib, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.systemd-boot.editor = false;
  boot.loader.timeout = 3;

  boot.loader.efi.efiSysMountPoint = "/efi";
  boot.loader.systemd-boot.xbootldrMountPoint = "/boot";

  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "udev.log_level=3"
  ];

  # The source host inits ram → swap early; zram gets priority on top
  # (see the swap entry in the host storage module).
  zramSwap.enable = true;
}
