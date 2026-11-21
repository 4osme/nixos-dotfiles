# The desktop user (matches the source machine's account).
{ pkgs, ... }:
{
  users.users."4osme" = {
    isNormalUser = true;
    description = "4osme";
    # wheel: admin; networkmanager: nmcli; input/video: session device access.
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "input"
    ];
    shell = pkgs.zsh;
    initialPassword = "nixos";
  };

  programs.zsh.enable = true;
}
