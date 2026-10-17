# The NixOS ports of fedora-hyprtomic's Vypr helpers (files/vypr/*), packaged
# as commands: hyprtomic-vypr-create-vm and hyprtomic-vypr-setup. The vypr-gpu
# helper library ships alongside them under share/hyprtomic/.
{
  pkgs,
  lib,
}:
let
  gpuLib = ../../files/system/vypr/vypr-gpu;

  commonInputs = with pkgs; [
    libvirt # virsh
    openssh # ssh-keygen, ssh
    curl
    python3
    coreutils
    gnugrep
    gnused
    gawk
    procps # ps (the patched vypr qemu_conf fallback)
    pciutils # lspci (vypr-gpu)
    findutils
  ];

  mkScript =
    name: file: extraInputs:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = commonInputs ++ extraInputs;
      text = builtins.replaceStrings [ "@VYPR_GPU_LIB@" ] [ "${gpuLib}" ] (builtins.readFile file);
    };

  createVm = mkScript "hyprtomic-vypr-create-vm" ../../files/vypr/hyprtomic-vypr-create-vm [
    pkgs.virt-manager
  ];
  setup = mkScript "hyprtomic-vypr-setup" ../../files/vypr/hyprtomic-vypr-setup [
    pkgs.virt-manager
    pkgs.xorriso
  ];
in
pkgs.runCommand "hyprtomic-vypr-scripts" { } ''
  mkdir -p $out/bin $out/share/hyprtomic
  cp ${createVm}/bin/hyprtomic-vypr-create-vm $out/bin/
  cp ${setup}/bin/hyprtomic-vypr-setup $out/bin/
  cp ${gpuLib} $out/share/hyprtomic/vypr-gpu
''
