{ ... }:
{
  imports = [
    ./gpu.nix
    ./npu.nix
    ./fingerprint.nix
    ./sunshine.nix
  ];

  # Machine specifics (Intel Core Ultra 200 Arrow Lake, CS9711F reader).
  # Everything below is declarative.
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
}
