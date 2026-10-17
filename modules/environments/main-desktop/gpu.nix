# Intel GPU stack of the source desktop (AGENTS.md: Intel GPU ドライバ関連,
# i915 ドライバの出禁と iGPU の xe ドライバ適応).
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

  # Arrow Lake-P iGPU (8086:7d51) runs on the xe driver like on the Fedora
  # host; ban i915 so it can never claim the iGPU. (The B580 itself is bound
  # to vfio-pci — see vfio.nix.)
  boot.blacklistedKernelModules = [ "i915" ];
}
