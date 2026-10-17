# Placeholder — run `nixos-generate-config --root /mnt` on the target machine
# at install time and replace this file with the generated
# hardware-configuration.nix, KEEPING the hardware parts (kernel modules and
# the like) and DROPPING its fileSystems/swapDevices block (the layout lives
# in hosts/main-desktop/storage.nix).
{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
