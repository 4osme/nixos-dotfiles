# The shipped ~/.zshrc sources zshrc.d/*.zsh at the end; the Fedora plugin
# paths (/usr/share/…) do not exist on NixOS, so provide them from the store
# through the same drop-in directory. The shipped .zshrc itself is synced from
# files/home/.zshrc by hyprtomic-config-sync.
{ pkgs, ... }:
{
  xdg.configFile."zshrc.d/10-nix-plugins.zsh".text = ''
    # NixOS: shell plugins (the source image shipped these under /usr/share).
    source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  '';
}
