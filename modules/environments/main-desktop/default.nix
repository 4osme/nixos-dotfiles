{ ... }:
{
  imports = [
    ./gpu.nix
    ./npu.nix
    ./vfio.nix
    ./vypr.nix
    ./fingerprint.nix
    ./sunshine.nix
    ./moonlight-web.nix
  ];

  # Machine specifics of the source "main" desktop (Intel Core Ultra 200+
  # Arrow Lake, Arc B580 for VFIO, CS9711F reader). Everything below is
  # declarative here; the Fedora scripts edited files at runtime instead.
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
}
