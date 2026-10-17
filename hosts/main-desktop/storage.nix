# Storage — TODO(manual): fill in the UUIDs of this machine.
#
# The reference is the current Fedora layout of this host (see the README):
#
#   nvme1n1p1  600M  vfat   ESP       -> /efi        (boot.loader.efi.efiSysMountPoint)
#   nvme1n1p2  2G    xfs    XBOOTLDR  -> /boot       (systemd-boot kernels + initrd)
#   nvme1n1p3  1.9T  btrfs  root      -> /           (@) and /home (@home)
#   nvme2n1p1  112G  swap             -> swap        (hibernate/resume target)
#   nvme0n1    954G  xfs    "develop" -> /mnt/develop (the develop environment's storage)
#
# Get the UUIDs with `blkid` (or lsblk -f) on the installed system / live ISO.
# NixOS install (manual partition step, done once):
#
#   sgdisk -n1:0:+600M -t1:ef00 /dev/nvme1n1            # ESP
#   sgdisk -n2:0:+2G   -t2:ea00 /dev/nvme1n1            # XBOOTLDR
#   sgdisk -n3:0:0     -t3:8304 /dev/nvme1n1            # root (Linux x86-64 root, btrfs)
#
#   mkfs.vfat -F32 -n BOOT /dev/nvme1n1p1
#   mkfs.xfs -L boot /dev/nvme1n1p2
#   mkfs.btrfs -L nixos /dev/nvme1n1p3
#   mount /dev/nvme1n1p3 /mnt
#   btrfs subvolume create /mnt/@ /mnt/@home
#   umount /mnt
#   mount -o subvol=@,compress=zstd:5,noatime /dev/nvme1n1p3 /mnt
#   mkdir -p /mnt/boot /mnt/efi /mnt/home /mnt/mnt/develop
#   mount /dev/nvme1n1p2 /mnt/boot
#   mount /dev/nvme1n1p1 /mnt/efi
#   mount -o subvol=@home,compress=zstd:5,noatime /dev/nvme1n1p3 /mnt/home
#
# Then `nixos-generate-config --root /mnt` and replace its fileSystems block
# with this file (keeping the rest of the generated hardware-configuration.nix
# in hosts/main-desktop/hardware-configuration.nix).
{
  lib,
  ...
}:
{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE-ROOT-BTRFS-UUID"; # TODO(manual)
    fsType = "btrfs";
    options = [
      "subvol=@"
      "compress=zstd:5"
      "noatime"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/REPLACE-ROOT-BTRFS-UUID"; # TODO(manual) — same btrfs
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd:5"
      "noatime"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE-BOOT-XFS-UUID"; # TODO(manual)
    fsType = "xfs";
    options = [ "defaults" ];
  };

  fileSystems."/efi" = {
    device = "/dev/disk/by-uuid/REPLACE-EFI-VFAT-UUID"; # TODO(manual)
    fsType = "vfat";
    options = [
      "umask=0077"
      "shortname=winnt"
    ];
  };

  # The develop storage (nvme0n1, label "develop"); nofail like the Fedora
  # fstab, so a missing disk never blocks boot.
  fileSystems."/mnt/develop" = {
    device = "/dev/disk/by-label/develop";
    fsType = "xfs";
    options = [
      "defaults"
      "noatime"
      "nofail"
    ];
  };

  # The 112G swap of nvme2n1p1; also the resume device for
  # `systemctl suspend-then-hibernate` (the hypridle listener).
  swapDevices = [
    {
      device = "/dev/disk/by-uuid/REPLACE-SWAP-UUID"; # TODO(manual)
      priority = 10; # below zram (zramSwap in modules/system/boot.nix)
    }
  ];
  boot.resumeDevice = lib.mkDefault "/dev/disk/by-uuid/REPLACE-SWAP-UUID"; # TODO(manual)
}
