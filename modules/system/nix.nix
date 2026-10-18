# Nix daemon settings, garbage collection and binary caches.
{ lib, ... }:
{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
      auto-optimise-store = true;

      substituters = [
        "https://cache.nixos.org/"
        # linux-cachyos-bore-lto-x86_64-v3 (xddxdd/nix-cachyos-kernel).
        "https://attic.xuyh0120.win/lantian"
        # The build workflow's Cachix cache (public).
        "https://j7b3y.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
        "j7b3y.cachix.org-1:zbi6DLNucBPdPbJqKWsFPqmuq77D7EzXNng1pRlmszE="
      ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true;
  };

  nixpkgs.config.allowUnfree = true;
  nix.channel.enable = false;
}
