# Home Manager delivery of the dotfiles. Every file under files/home (plus the
# host's files/home-<host> overlay, e.g. host.lua on
# main-desktop) becomes a read-only Nix store link in $HOME.
#
# The tree has (almost) no runtime writers: app theming files are written at
# runtime by Dux Shell (~/.config/hypr/dms/, qt{5,6}ct, dank-colors.css, …),
# outside this tree. fcitx5's own state (profile, i.e. the IM group and the
# selected engine) is deliberately NOT managed here: fcitx5 rewrites it at
# runtime, so a read-only store link would make engine changes non-persistent.
# Unmanaged paths that stay writable by design:
#   ~/.config/hypr/local.conf    — hyprland.lua loads it last (debug escape hatch)
#   ~/.config/fcitx5/profile    — written by fcitx5 (engine / group order)
#   ~/.config/nvim/lazy-lock.json — lazy.nvim rewrites it on install/update (see below)
{
  lib,
  pkgs,
  dotfilesOverlay,
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

  # The nvim tree in this repository also carries material that belongs to the
  # repository, not to the editor: agent docs/skills, an unused neoconf file and
  # the git ignore rules. Only the editor configuration is linked into
  # ~/.config/nvim.
  nvimRepoOnlyFiles = [
    ".config/nvim/AGENTS.md"
    ".config/nvim/README.md"
    ".config/nvim/.neoconf.json"
    ".config/nvim/.gitignore"
  ];
  nvimRepoOnlyDirs = [ ".config/nvim/.opencode/" ];

  # The host overlay wins per file (host.lua, relaxed hypridle.conf, the
  # Sunshine helper, …).
  #
  # lazy-lock.json is delivered by the activation below instead of as a store
  # link: lazy.nvim `assert`s on writing the lockfile, so a read-only link
  # fails the first `install` (fresh home) and every `:Lazy update`.
  files = lib.filterAttrs (n: _: !(lib.any (prefix: lib.hasPrefix prefix n) nvimRepoOnlyDirs)) (
    removeAttrs (
      walk ../../files/home "" // (if dotfilesOverlay != null then walk dotfilesOverlay "" else { })
    ) ([ ".config/nvim/lazy-lock.json" ] ++ nvimRepoOnlyFiles)
  );

  xdgFiles = lib.filterAttrs (n: _: lib.hasPrefix ".config/" n) files;
  homeFiles = lib.filterAttrs (n: _: !(lib.hasPrefix ".config/" n)) files;

  # Pinned plugin versions stay declarative (files/home/.config/nvim): the
  # repository/flake owns the lockfile. To bump versions, run `:Lazy update` on
  # a machine and copy the resulting ~/.config/nvim/lazy-lock.json back into
  # files/home/.config/nvim/lazy-lock.json; every rebuild then rewrites the
  # writable copy whenever the contents differ.
  nvimLockfile = ../../files/home/.config/nvim/lazy-lock.json;
in
{
  _module.args.dotfilesOverlay = lib.mkDefault null;

  home.activation.nvimLockfile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    lock="$HOME/.config/nvim/lazy-lock.json"
    if ! ${pkgs.diffutils}/bin/cmp -s ${nvimLockfile} "$lock"; then
      run mkdir -p "$HOME/.config/nvim"
      run ${pkgs.coreutils}/bin/install -m 0644 ${nvimLockfile} "$lock"
    fi
  '';

  # ~/.config/** goes through xdg.configFile (the .config prefix is stripped).
  xdg.configFile = lib.mapAttrs' (
    n: source: lib.nameValuePair (lib.removePrefix ".config/" n) { inherit source; }
  ) xdgFiles;

  # Everything else (~/.zshrc, ~/.local/share/**, …) stays a plain home.file.
  home.file = lib.mapAttrs (_: source: { inherit source; }) homeFiles;
}
