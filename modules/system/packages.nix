# Small set of system-wide CLI tools (the bulk of the AGENTS.md tool list is
# installed per user in home/packages.nix).
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    vim
    pciutils
    usbutils
    lsof
    killall
  ];
}
