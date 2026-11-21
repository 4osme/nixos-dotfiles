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

  fileSystems."/games" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "btrfs";
    options = [
      "subvol=@games"
      "compress=zstd:5"
      "noatime"
    ];
  };
}
