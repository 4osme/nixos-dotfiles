# Fonts of the source install: Noto (incl. CJK), Twitter Color Emoji, HackGen
# Console NF (ghostty), JetBrains Mono and Google Sans Flex (fcitx5 UI).
# The user fontconfig tree (99-twemoji.conf preference) ships via files/home.
{ pkgs, ... }:
{
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      twemoji-color-font
      hackgen-font
      jetbrains-mono
      google-sans-flex
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = [
          "Noto Sans"
          "Noto Sans CJK JP"
        ];
        serif = [
          "Noto Serif"
          "Noto Serif CJK JP"
        ];
        monospace = [
          "HackGen Console NF"
          "Noto Sans Mono CJK JP"
        ];
        emoji = [ "Twitter Color Emoji" ];
      };
    };
  };
}
