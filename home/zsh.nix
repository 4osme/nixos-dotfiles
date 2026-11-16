# The shipped ~/.zshrc sources zshrc.d/*.zsh at the end; the Fedora plugin
# paths (/usr/share/…) do not exist on NixOS, so provide them from the store
# through the same drop-in directory. The .zshrc itself is delivered by Home
# Manager from files/home/.zshrc.
{ pkgs, ... }:
{
  xdg.configFile."zshrc.d/10-nix-plugins.zsh".text = ''
    # NixOS: shell plugins from nixpkgs.
    source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  '';
}
