# The desktop user (matches the source machine's account).
{ pkgs, ... }:
{
  users.users.underdone = {
    isNormalUser = true;
    description = "underdone";
    # wheel: admin; networkmanager: nmcli; libvirtd+kvm: password-less KVM
    # control (the source install adds the user to the KVM groups); input/video:
    # the session groups setup-groups.sh granted on Fedora.
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "input"
      "libvirtd"
      "kvm"
    ];
    shell = pkgs.zsh;
    # TODO(manual): run `passwd underdone` right after the first login.
    initialPassword = "nixos";
  };

  programs.zsh.enable = true;
}
