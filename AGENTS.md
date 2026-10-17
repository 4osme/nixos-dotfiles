# リポジトリの目的

```../fedora-hyprtomic/```のシステムをnixosへ移植したものをdotfilesとして管理し、保守することが目的。

## fedora-hyprtomicとは
fedora-hyprtomicはシステムの中核を担うHostイメージとhyprlandのコンポーネントを実行するhyprtomic-guiイメージで構成されているFedora-Atomicベースのディストリビューションで、ユーザーが必要なソフトウェアはdistroboxコンテナで実行環境ごとユーザーが用意する構成となっている。

# 移行後のdotfilesの内容  
NixOS + Home Manager -> OSの基本的な部分に加え、sddm theme,hyprtomic-guiでカバーしていたguiコンポーネント(独自でビルドしていたhyprbindなども含む),{hyprland,gtk,qt,ghostty}のconfig,サウンドや通信関係の制御,japanese-ime,distrobox基盤,KVM基盤(規定のユーザーを認証なしでkvm制御できるようにグループに加える),各環境に必要なツール類(fastfetch,git,github-cli,tea-cli(giteaのcli),vscode,vesktop,MissionCenter,Bitwarden,zsh,neovim,ghostty,mozkey,google-chrome,EasyEffects,sshfs)  
main-desktop環境モジュール -> Vypr統合,Intel ARC B580のVFIO割り当て(Windows VMを扱うため),CS9711Fingprintドライバ,Intel NPUランタイム,Intel GPUドライバ関連,i915ドライバの出禁とiGPUのxeドライバ適応,スリープに移行する待機時間の緩和  
dell-laptop環境モジュール -> Intel NPUランタイム,Intel GPUドライバ関連,電源ボタンや蓋閉じ時の実行内容変更(ハイバネーション),省電力のための設定,tpm2とluksによるディスク暗号化管理,tailsale統合,waybarにバッテリー残量表示や充電ステータスのフォーカス表示,ディスプレイのカスタムedid適応,  

## 検討している項目  
FileManager: nemoから[sigma-file-manager](https://github.com/aleksey-hoffman/sigma-file-manager)へ移行してnemoは除外する  
Flatpak    : 半年ほど前ではflatpakとnixosの相性が悪かったため悩んでいたがサポートが進んでいて十分実用可能レベルであればいくつかのツールがnixパッケージに依存しなくなるため導入、更新の手間がかなり軽減される可能性がある(vesktop,MissionCenter,Bitwarden,google-chrome,EasyEffects) ※ DellLaptopでは加えて[KTailctl](https://github.com/f-koehler/KTailctl)がビルド不要になる。  

# 要望  
- GitHub Actionによるビルドとバイナリキャッシュの管理  
- nix flake updateの自動実行とpull requestの作成と主導マージによる更新の自動化  
- systemd-bootをブートローダーとして使うこと  
- kernelは[linux-cachyos-bore-lto-x86_64-v3](https://github.com/xddxdd/nix-cachyos-kernel)で統一

# ユーザーによる手動での定義が必要な項目  
- 各環境のストレージ  
- dell-laptopのedid組み込み  

# 関連するリンク  
- [mozkey](https://github.com/Masterisk-F/fcitx-mozkey)
- [Vypr](https://github.com/Amzi-01/Vypr)
