# KVM/libvirt foundation (AGENTS.md: KVM基盤 — the desktop user controls KVM
# without authentication: the libvirtd group carries the
# org.libvirt.unix.manage polkit rule, kvm grants the device).
{ pkgs, lib, ... }:
{
  virtualisation.libvirtd = {
    enable = true;
    # Do not start guests at boot; Vypr starts the Windows VM on demand.
    onBoot = "ignore";
    qemu = {
      swtpm.enable = true;
      vhostUserPackages = [ pkgs.virtiofsd ];
      # The qemu.conf `user`/`group` for Vypr live in the main-desktop
      # environment module (they belong to the Vypr integration).
    };
    # Hooks for the Vypr GPU swap go here when that workflow is wanted:
    # virtualisation.libvirtd.hooks.qemu."vypr-gpu" = pkgs.vypr + "/share/vypr/hooks/vypr-gpu";
  };

  environment.systemPackages = with pkgs; [
    virt-manager
    virtiofsd
  ];
}
