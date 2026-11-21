# Extra matugen templates that Dux Shell runs on every wallpaper change /
# theme switch. matugen requires absolute paths, so they are built from
# home.homeDirectory here instead of hardcoding /home/<user> in files/home
# (the template itself still ships from files/home/.config/matugen/templates).
{ config, ... }:
{
  xdg.configFile."matugen/config.toml".text = ''
    # Extra matugen templates run alongside the ones Dux Shell ships — executed
    # by DMS on every wallpaper change / theme switch.
    [config]

    # Ghostty's native GTK UI (native tab bar): ~/.config/ghostty/gtk.css is NOT
    # Home Manager-managed — matugen owns it, so the design lives in the template.
    [templates.ghosttygtk]
    input_path = '${config.home.homeDirectory}/.config/matugen/templates/ghostty-gtk.css'
    output_path = '${config.home.homeDirectory}/.config/ghostty/gtk.css'
  '';
}
