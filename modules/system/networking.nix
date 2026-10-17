# NetworkManager + Bluetooth like the source host (BlueZ and NM are host-side
# services; the shell's control center talks to them over the system bus).
{
  networking.networkmanager.enable = true;

  # The hostname is set per host (hosts/<name>/default.nix).

  networking.firewall.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
}
