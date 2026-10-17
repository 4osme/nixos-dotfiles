# hyprtomic-config-sync — the NixOS replacement for the Fedora image's
# `ujust sync-skel-config` / `ujust overwrite=1 sync-skel-config`.
#
# The dotfiles stay writable files in $HOME (the theme system rewrites gtk.css,
# qt colors, rofi colors, hypr/theme.lua, …; hyprland.lua/local.conf,
# monitors.lua and workspaces.lua are machine state) exactly like the source
# install, so they must not become read-only Nix store symlinks. Store copies of
# files/home (+ the files/home-<host> overlay passed in by the flake) are synced
# with the same skip/overwrite + manifest-prune semantics as the original ujust
# recipe.
{
  pkgs,
  lib,
  dotfilesOverlay ? null,
  ...
}:
let
  overlayCopy = lib.optionalString (dotfilesOverlay != null) ''
    # Host overlay wins over the common tree (e.g. relaxed hypridle timeouts
    # on main-desktop). chmod first: the store files copied above are
    # read-only, so overwriting them needs a writable target (or cp -f).
    chmod -R u+w $out
    cp -af ${dotfilesOverlay}/. $out/
  '';

  dotfiles = pkgs.runCommand "hyprtomic-dotfiles" { } ''
    mkdir -p $out
    cp -a ${../files/home}/. $out/
    ${overlayCopy}
  '';

  sync = pkgs.writeShellApplication {
    name = "hyprtomic-config-sync";
    runtimeInputs = [
      pkgs.rsync
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnugrep
    ];
    text = ''
      usage() {
        echo "usage: hyprtomic-config-sync [--overwrite]"
        echo "  (default: copy files that do not exist yet)"
        echo "  --overwrite: replace managed files and prune files a previous"
        echo "               overwrite synced that the config no longer ships"
      }

      overwrite=0
      for arg in "$@"; do
        case "$arg" in
          ""|-h|--help) usage; exit 0 ;;
          -o|--overwrite) overwrite=1 ;;
          *) echo "hyprtomic-config-sync: unknown argument: $arg" >&2; usage >&2; exit 2 ;;
        esac
      done

      SRC=${dotfiles}
      STATE="$HOME/.local/state/hyprtomic"
      MANIFEST="$STATE/skel-manifest"

      install -d "$STATE"

      if [ "$overwrite" = 1 ]; then
        new_manifest="$(mktemp)"
        trap 'rm -f "$new_manifest"' EXIT

        find "$SRC" -mindepth 1 ! -type d -printf '%P\n' | LC_ALL=C sort > "$new_manifest"

        # Prune files a previous overwrite synced that the config has since
        # removed. Only when a manifest from a prior overwrite exists: paths
        # like .local/share are shared with non-managed data, so never delete
        # speculatively on a first run.
        if [ -f "$MANIFEST" ]; then
          while IFS= read -r relpath; do
            [ -n "$relpath" ] || continue
            target="$HOME/$relpath"
            rm -f "$target"

            parent="$(dirname "$target")"
            while [ "$parent" != "$HOME" ]; do
              rmdir "$parent" 2>/dev/null || break
              parent="$(dirname "$parent")"
            done
          done < <(comm -23 "$MANIFEST" "$new_manifest")
          echo "Replacing managed dotfiles and pruning removed files ..."
        else
          echo "Replacing managed dotfiles (first overwrite -- seeding manifest, no prune) ..."
        fi

        rsync -a "$SRC/" "$HOME/"
        cp "$new_manifest" "$MANIFEST"
      else
        echo "Syncing dotfiles into \$HOME (skipping files that already exist) ..."
        rsync -a --ignore-existing "$SRC/" "$HOME/"
      fi

      echo
      echo "Done. Run 'hyprctl reload' or log out and back in to apply."
    '';
  };
in
{
  home.packages = [ sync ];
}
