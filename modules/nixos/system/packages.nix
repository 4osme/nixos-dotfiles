# Small set of system-wide CLI tools; desktop tools are installed per user.
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
