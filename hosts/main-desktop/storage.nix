{ lib, ... }:
{
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "btrfs";
    options = [
      "subvol=@"
      "compress=zstd:5"
      "noatime"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd:1"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "btrfs";
    options = [
      "subvol=@nix"
      "compress=zstd:5"
      "noatime"
    ];
  };

  fileSystems."/mnt/develop" = {
    device = "/dev/disk/by-label/develop";
    fsType = "xfs";
    options = [
      "defaults"
      "noatime"
      "nofail"
    ];
  };

  swapDevices = [
    {
      device = "/dev/disk/by-label/swapart";
      # Below zram (zramSwap.priority = 10 in modules/system/boot.nix), so the
      # disk swap is only used once zram is full.
      priority = 5;
    }
  ];
  boot.resumeDevice = lib.mkDefault "/dev/disk/by-label/swapart";
}
