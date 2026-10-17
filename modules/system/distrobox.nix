# Distrobox foundation (AGENTS.md: ユーザーが必要なソフトウェアは distrobox
# コンテナで実行環境ごとに用意する — podman + distrobox, no GUI container
# anymore; the shell runs natively).
{ pkgs, ... }:
{
  virtualisation.podman.enable = true;

  environment.systemPackages = [ pkgs.distrobox ];
}
