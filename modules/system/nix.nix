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
        # TODO(manual): the Cachix cache from the build workflow — create the
        # cache, set CACHIX_CACHE_NAME/CACHIX_AUTH_TOKEN in the repo secrets and
        # add `"https://<cache>.cachix.org"` here plus its public key below.
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
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
