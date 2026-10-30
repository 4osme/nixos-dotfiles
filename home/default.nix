# Per-user desktop: the Dux Labs suite (Dux Shell + utils), Home
# Manager-managed dotfiles and the small user services.
{
  pkgs,
  inputs,
  hostName,
  lib,
  ...
}:
{
  imports = [
    ./packages.nix
    ./zsh.nix
    ./services.nix
    ./dotfiles.nix
    # The Dux modules replace the old Home Manager component gtk/qt theme set
    # (theme.nix is gone): Dux Shell's matugen theming picks the wallpaper and
    # generates GTK/Qt colors.
    inputs.dms.homeModules.dank-material-shell
    inputs.dsearch.homeModules.default
    inputs.dfiles.homeModules.default
    inputs.dcal.homeModules.dank-calendar
  ]
  ++ lib.optional (hostName == "main-desktop") ./sunshine.nix
  ++ lib.optional (hostName == "main-desktop") ./moonlight-web.nix;

  home.username = "underdone";
  home.homeDirectory = "/home/underdone";
  home.stateVersion = "26.05";

  programs.dank-material-shell = {
    enable = true;
    # dms.service starts with the graphical session (nothing autostarts
    # hyprland-scale, so no per-compositor spawn is needed).
    systemd.enable = true;
    enableSystemMonitoring = true;
    enableDynamicTheming = true;
  };

  # dgop backs the system-monitoring widgets; DMS calls it from PATH.
  programs.dux-calendar.systemd.enable = true;

  programs.dsearch.enable = true;

  # File manager (replaced sigma-file-manager): a resident service keeps
  # windows fast and answers org.freedesktop.FileManager1.
  programs.dux-files = {
    enable = true;
    systemd.enable = true;
  };

  # Declarative default wallpaper for Dux Shell. Session state stays
  # user-writable (the control-center wallpaper picker and per-monitor
  # mode keep working): the activation only seeds `wallpaperPath` when the
  # session file is missing or does not have the key yet.
  home.activation.defaultDmsWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    sessionDir="$HOME/.local/state/DankMaterialShell"
    session="$sessionDir/session.json"
    wallpaper="$HOME/.local/share/backgrounds/wallpaper.jpg"
    jq="${pkgs.jq}/bin/jq"
    if ! "$jq" -e 'has("wallpaperPath")' "$session" >/dev/null 2>&1; then
      mkdir -p "$sessionDir"
      if [ -f "$session" ]; then
        "$jq" --arg p "$wallpaper" '.wallpaperPath = $p' "$session" > "$session.tmp" \
          && mv "$session.tmp" "$session"
      else
        printf '{"wallpaperPath": "%s"}\n' "$wallpaper" > "$session"
      fi
    fi
  '';

  # Read by systemd user services (the compositor sets the same values for
  # the graphical session in hyprland.lua). Qt theming goes through qt6ct,
  # whose color files Dux Shell generates (application-themes Option 2).
  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt6ct";
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "36";
  };

  # Dux Files is the default file manager.
  xdg.mimeApps = {
    enable = true;
    defaultApplications."inode/directory" = "dev.duxlabs.files.desktop";
  };
}
