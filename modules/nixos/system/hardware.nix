# Firmware/microcode + graphics base of every machine.
{ ... }:
{
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.graphics.enable = true;
}
