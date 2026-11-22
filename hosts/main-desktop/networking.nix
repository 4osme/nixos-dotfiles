# Do not bind the NAS VLAN to a MAC, PCI path, or predictable interface name.
# The existing NetworkManager untagged/DHCP connection remains untouched.
{ pkgs, ... }:
{
  boot.kernelModules = [ "8021q" ];

  systemd.services.main-desktop-vlan202 = {
    description = "NAS VLAN 202 on the sole physical Ethernet port";
    wantedBy = [ "multi-user.target" ];
    requires = [ "NetworkManager.service" ];
    after = [ "NetworkManager.service" ];
    partOf = [ "NetworkManager.service" ];
    unitConfig.StartLimitIntervalSec = 0;
    path = [
      pkgs.coreutils
      pkgs.networkmanager
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash ${./vlan202.sh}";
      Restart = "on-failure";
      RestartSec = 30;
      UMask = "0077";
    };
  };
}
