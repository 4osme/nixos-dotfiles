# Vypr integration (AGENTS.md: Vypr 統合). The Fedora image shipped the
# binaries in a separate host tag and a setup script that edited system files;
# here the binaries come from pkgs/vypr and the system state is declarative.
{ pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [
    vypr
    hyprtomic-vypr-scripts
    virt-manager
    virt-viewer
    virtiofsd
    swtpm
    xorriso
    pciutils
    usbutils
    libosinfo
    xdg-user-dirs
    OVMF # secure-boot uefi firmware for virt-install
  ];

  # Vypr reads the guest RAM through the running QEMU's /proc/<pid>/fd, which
  # requires QEMU to run as the desktop user — the Fedora image patched
  # /etc/libvirt/qemu.conf (`user=`/`group=`) the same way. `namespaces = []`
  # is the NixOS default that the replaced default would have carried.
  virtualisation.libvirtd.qemu.verbatimConfig = ''
    namespaces = []
    user = "underdone"
    group = "users"
  '';

  # swtpm's local CA state directory (the Fedora setup healed this path).
  systemd.tmpfiles.rules = [
    "d /var/lib/swtpm-localca 0750 tss root - -"
  ];
}
