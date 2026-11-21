# Intel GPU stack for the Arrow Lake desktop.
{ pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver # VA-API (iHD)
      vpl-gpu-rt # oneVPL / Quick Sync runtime
      intel-compute-runtime # OpenCL / Level Zero
      level-zero
      intel-gpu-tools
      libva-utils
      vulkan-tools
    ];
  };

  boot.blacklistedKernelModules = [ "i915" ];
}
