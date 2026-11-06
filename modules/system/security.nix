# Session security bits: polkit (auth dialogs are served by Dux Shell's
# built-in polkit agent), the uinput device for ydotoold and the fingerprint
# gate helper shared by SDDM/hyprlock (see modules/system/sddm.nix).
{ pkgs, ... }:
{
  security.polkit.enable = true;

  # modules-load.d/uinput.conf + udev/rules.d/99-uinput.rules of the Fedora
  # image (on-screen keyboard / ydotoold).
  boot.kernelModules = [ "uinput" ];
  services.udev.extraRules = ''
    SUBSYSTEM=="misc", KERNEL=="uinput", MODE="0660", GROUP="input"
  '';
}
