# Home Manager delivery of the dotfiles — the NixOS-native replacement for the
# fedora-hyprtomic /etc/skel sync. Every file under files/home (plus the
# host's files/home-<host> overlay, e.g. monitors.lua / host.lua on
# main-desktop) becomes a read-only Nix store link in $HOME.
#
# The tree has (almost) no runtime writers: fcitx5 etc. only read their
# configs, and app theming files are written at runtime by Dux Shell
# (~/.config/hypr/dms/, qt{5,6}ct, dank-colors.css, …), outside this tree. The
# one unmanaged path left is ~/.config/hypr/local.conf (hyprland.lua loads it
# last), kept as the debug escape hatch.
{
  config,
  lib,
  dotfilesOverlay ? null,
  ...
}:
let
  # Flat map of "<relative path>" -> source path for every file in a tree.
  walk =
    dir: prefix:
    lib.concatMapAttrs (
      name: type:
      let
        full = dir + "/${name}";
        rel = "${prefix}${name}";
      in
      if type == "directory" then walk full "${rel}/" else { "${rel}" = full; }
    ) (builtins.readDir dir);

  # The host overlay wins per file (monitors.lua on main-desktop, relaxed
  # hypridle.conf, host.lua, the Sunshine helper, …).
  files = walk ../files/home "" // (if dotfilesOverlay != null then walk dotfilesOverlay "" else { });

  xdgFiles = lib.filterAttrs (n: _: lib.hasPrefix ".config/" n) files;
  homeFiles = lib.filterAttrs (n: _: !(lib.hasPrefix ".config/" n)) files;
in
{
  # ~/.config/** goes through xdg.configFile (the .config prefix is stripped).
  xdg.configFile = lib.mapAttrs' (
    n: source: lib.nameValuePair (lib.removePrefix ".config/" n) { inherit source; }
  ) xdgFiles;

  # Everything else (~/.zshrc, ~/.local/share/**, …) stays a plain home.file.
  home.file = lib.mapAttrs (_: source: { inherit source; }) homeFiles;
}
