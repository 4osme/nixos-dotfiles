# main-desktop — Intel Core Ultra 200 (Arrow Lake) desktop.
{ ... }:
{
  imports = [
    ../../modules/environments/main-desktop
    ./storage.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "main-desktop";
}
