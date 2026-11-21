# NixOS plugins come from the flake-pinned nixpkgs, without network clones.
# The shared zshrc retains its antidote fallback for non-NixOS environments.
{ pkgs, ... }:
{
  xdg.configFile."zshrc.d/10-nix-plugins.zsh".text = ''
    fpath=(${pkgs.zsh-completions}/share/zsh/site-functions $fpath)
    source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    typeset -g DOTFILES_NIX_ZSH_HIGHLIGHT=${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  '';
}
