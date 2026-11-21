{
  home-manager = {
    extraSpecialArgs.dotfilesOverlay = ../../files/home-main-desktop;
    users."4osme".imports = [
      ../../home/4osme
      ../../modules/home-manager/sunshine.nix
    ];
  };
}
