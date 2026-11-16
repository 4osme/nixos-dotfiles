# The desktop user (matches the source machine's account).
{ pkgs, ... }:
{
  users.users.underdone = {
    isNormalUser = true;
    description = "underdone";
    # wheel: admin; networkmanager: nmcli; input/video: session device access.
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "input"
    ];
    shell = pkgs.zsh;
    # TODO(manual): run `passwd underdone` right after the first login.
    initialPassword = "nixos";
  };

  programs.zsh.enable = true;
}
