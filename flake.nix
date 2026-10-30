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

    # Serein (native Discord client). Its flake pins nixos-unstable with Rust
    # 1.98.1; our nixpkgs 26.05 ships Rust 1.95, which is too old, so keep this
    # input's nixpkgs un-followed. The package is self-contained.
    serein.url = "github:ViceVerse-cz/Serein";

    # Dux Labs suite: Dux Shell (bar / launcher / control center / theming) and
    # its utils. All follow our nixpkgs (they support 26.05 natively).
    dms = {
      url = "github:duxlabs-dev/dux-shell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dgop = {
      url = "github:duxlabs-dev/dux-gop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dsearch = {
      url = "github:duxlabs-dev/dux-search";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dcal = {
      url = "github:duxlabs-dev/dux-calendar";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dfiles = {
      url = "github:duxlabs-dev/dux-files";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
          moonlight-web-stream
          sunshine
          ;
        serein = inputs.serein.packages.${pkgs.stdenv.hostPlatform.system}.default;
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
