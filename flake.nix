{
  description = "HyprTomic NixOS — NixOS + Home Manager port of fedora-hyprtomic";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # linux-cachyos-bore-lto-x86_64-v3 (Hydra-built + binary-cached).
    # The flake pins its own nixpkgs (nixos-unstable-small); keep that input
    # un-followed and use overlays.pinned for cache hits (see README).
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      # mkHost takes the host directory and its dotfiles overlay explicitly
      # (paths must be static literals: pure evaluation cannot concatenate
      # paths).
      mkHost =
        {
          hostName,
          hostDir,
          dotfilesOverlay ? null,
        }:
        lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs hostName dotfilesOverlay;
          };
          modules = [
            ./modules/system
            ./modules/desktop
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hm-backup";
                extraSpecialArgs = {
                  inherit inputs hostName dotfilesOverlay;
                };
                users.underdone = import ./home;
              };
            }
            hostDir
          ];
        };

      hosts = {
        main-desktop = mkHost {
          hostName = "main-desktop";
          hostDir = ./hosts/main-desktop;
          dotfilesOverlay = ./files/home-main-desktop;
        };
        # dell-laptop: add an entry here (+ hosts/ and files/home-dell-laptop/
        # when it has an overlay); see the README.
      };

      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };

      forAllSystems = f: lib.genAttrs [ "x86_64-linux" ] (system: f (pkgsFor system));
    in
    {
      overlays.default = import ./overlays;

      nixosConfigurations = hosts;

      # `nix flake check` / the build workflow evaluates and builds these; the
      # binary cache fills from the same derivations.
      checks = lib.mapAttrs' (
        name: cfg: lib.nameValuePair "system-${name}" cfg.config.system.build.toplevel
      ) hosts;

      # Custom packages, buildable on their own (`nix build .#hyprbind` …) so CI
      # and humans can iterate without a full system build.
      packages = forAllSystems (pkgs: {
        inherit (pkgs)
          hyprbind
          hypremoji
          vypr
          hyprtomic-vypr-scripts
          fcitx5-mozkey-ibg
          sddm-hyprtomic-theme
          google-sans-flex
          libfprint-cs9711
          resolve-icons
          sunshine
          ;
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
