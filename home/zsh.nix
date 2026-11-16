# The shipped ~/.zshrc sources ~/.config/zshrc.d/*.zsh before it loads the
# antidote plugins; the Fedora paths (/usr/share/…, ~/.local/share/antidote)
# do not exist on NixOS, so the store locations are provided through the same
# drop-in directory. The .zshrc itself is delivered by Home Manager from
# files/home/.zshrc.
#
# Plugins come from antidote (not from the nixpkgs zsh-* plugin packages):
# ~/.zsh_plugins.txt is delivered read-only by dotfiles.nix, so the NixOS and
# distrobox shells share one plugin list. Only antidote itself is taken from
# nixpkgs; its clone cache stays the default ~/.cache/antidote.
{ pkgs, ... }:
{
  xdg.configFile."zshrc.d/10-antidote.zsh".text = ''
    # NixOS: point ~/.zshrc at the nixpkgs antidote instead of a manual clone.
    export ANTIDOTE_ZSH_FILE=${pkgs.antidote}/share/antidote/antidote.zsh
  '';
}
