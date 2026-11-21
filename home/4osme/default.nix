{
  imports = [ ../../modules/home-manager/desktop.nix ];

  home.username = "4osme";
  home.homeDirectory = "/home/4osme";

  # Home Manager compatibility baseline from the initial setup.
  home.stateVersion = "26.05";
}
