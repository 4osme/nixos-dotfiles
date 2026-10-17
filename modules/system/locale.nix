# Japanese desktop: locale, keymap, fcitx5 (the mozkey IbG engine) and the
# environment variables the session expects.
{ pkgs, lib, ... }:
{
  time.timeZone = "Asia/Tokyo";

  i18n.defaultLocale = "ja_JP.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ja_JP.UTF-8";
    LC_IDENTIFICATION = "ja_JP.UTF-8";
    LC_MEASUREMENT = "ja_JP.UTF-8";
    LC_MONETARY = "ja_JP.UTF-8";
    LC_NAME = "ja_JP.UTF-8";
    LC_NUMERIC = "ja_JP.UTF-8";
    LC_PAPER = "ja_JP.UTF-8";
    LC_TELEPHONE = "ja_JP.UTF-8";
    LC_TIME = "ja_JP.UTF-8";
  };

  console.keyMap = "jp106";

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      # mozkey IbG (the engine in ~/.config/fcitx5/profile) is not in nixpkgs;
      # pkgs/mozkey packages the upstream prebuilt release.
      addons = [ pkgs.fcitx5-mozkey-ibg ];
      # Keep the classic GTK/Qt immodule wiring the source config exports
      # (GTK_IM_MODULE=fcitx etc. in hyprland.lua) instead of the Wayland
      # frontend.
      waylandFrontend = false;
    };
  };
}
