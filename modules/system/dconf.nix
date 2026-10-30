# dconf: just the profile/database plumbing on the system side. GTK/Qt theme
# values are written at runtime by Dux Shell's theming (matugen).
{ ... }:
{
  programs.dconf.enable = true;
}
