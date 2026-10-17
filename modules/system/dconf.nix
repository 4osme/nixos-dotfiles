# dconf: just the profile/database plumbing on the system side. The actual
# values are Home Manager's dconf.settings (home/theme.nix), so there is no
# system database to maintain here anymore.
{ ... }:
{
  programs.dconf.enable = true;
}
