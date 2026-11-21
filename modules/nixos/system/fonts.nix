# Fonts of the source install: Noto (incl. CJK), OpenMoji Color, HackGen
# Console NF (ghostty), JetBrains Mono and Roboto Flex (variable font for the
# fcitx5 UI; replaces the COPR-only Google Sans Flex).
# The user fontconfig tree (99-twemoji.conf preference) ships via files/home.
{ pkgs, ... }:
{
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      openmoji-color
      hackgen-nf-font
      jetbrains-mono
      roboto-flex
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
        emoji = [ "OpenMoji Color" ];
      };
    };
  };
}
