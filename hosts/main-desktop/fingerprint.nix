# CS9711F fingerprint reader (2541:0236 "Chipsailing CS9711Fingprint").
# Upstream libfprint does not support it; the Fedora host used the COPR
# cwt/libfprint-cs9711 (the archeYR libfprint-CS9711 fork, with the 1500ms
# retry-delay patch). pkgs/libfprint-cs9711 builds the same fork; swap
# libfprint for it so fprintd picks it up (services.fprintd in sddm.nix).
{ lib, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      libfprint = final.libfprint-cs9711;
    })
  ];
}
