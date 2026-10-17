# main-desktop — the environment that replaces the current distrobox host
# ("this machine"): Intel Core Ultra 200 (Arrow Lake) desktop with the Arc
# B580 assigned to a Vypr Windows VM.
{ ... }:
{
  imports = [
    ../../modules/environments/main-desktop
    ./storage.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "main-desktop";
}
