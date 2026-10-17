# Intel NPU (8086:7d1d, intel_vpu): driver + firmware + Level Zero userspace.
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.intel-npu-driver ];

  # The kernel module is in-tree (CachyOS base ≫ 6.14); the firmware and the
  # Level Zero validation tools come from the package's `firmware` output.
  hardware.firmware = [ pkgs.intel-npu-driver.firmware ];
}
