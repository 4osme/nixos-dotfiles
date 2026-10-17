# Flatpak support (the source host manages system flatpaks; the quickshell
# launcher has a Flatpak source chip). 26.05's services.flatpak only takes
# enable/package, so the preinstalled apps (recipe-common-dotfiles.yml
# default-flatpaks) are installed by a small one-shot service instead.
{ pkgs, ... }:
{
  services.flatpak.enable = true;

  systemd.services.flatpak-apps = {
    description = "Install the preinstalled Flatpak apps (firefox, loupe)";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      for app in org.mozilla.firefox org.gnome.Loupe; do
        flatpak info --system "$app" >/dev/null 2>&1 || \
          flatpak install --system -y --noninteractive flathub "$app"
      done
    '';
  };
}
