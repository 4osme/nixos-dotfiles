# main-desktop — Intel Core Ultra 200 (Arrow Lake) desktop.
{ ... }:
{
  imports = [
    ../../modules/nixos/system
    ../../modules/nixos/desktop
    ../../modules/nixos/home-manager.nix
    ./gpu.nix
    ./npu.nix
    ./fingerprint.nix
    ./sunshine.nix
    ./users.nix
    ./home.nix
    ./networking.nix
    ./storage.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "main-desktop";

  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  # NixOS compatibility baseline from the initial installation.
  system.stateVersion = "26.05";
}
