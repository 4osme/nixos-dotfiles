# NixOS dotfiles

NixOSとHomeManagerを使ったホストの宣言的なシステム管理とdistrobox/Vyprを使った非宣言的なゲスト環境のハイブリッド型を目指したdotfiles。

## 独自パッケージの出典

| パッケージ | 出典 | 備考 |
|---|---|---|
| `hyprbind` 0.1.4 | ry2x/HyprBind | MIT/OFL。ソースからビルド |
| `hypremoji` 1.3.0 | Musagy/hypremoji | AUR `hypremoji` と同一 upstream。upstream に Cargo.lock が無いため生成済み lock を `pkgs/hypremoji/` に固定 |
| `fcitx5-mozkey-ibg` 0.10.4 | kazormia296/mozkey-ibg の Arch prebuilt | AUR `mozkey-ibg-bin` と同一成果物。fcitx5 のみ autoPatchelf (付属 llama-server/mozc_server はほぼ静的) |
| `vypr` 0.5.0 | Amzi-01/Vypr | Unlicense。4 パッチ + `vypr-setup.exe` 同梱 |
| `sddm-hyprtomic-theme` | Keyitdev/sddm-astronaut-theme + `files/sddm-theme` | GPL-3.0 |
| `google-sans-flex` | ririko66z/dots-hyprland COPR RPM | OFL。Fedora の gui-04-fonts.sh と同じ成果物 |
| `libfprint-cs9711` 1.94.10 | archeYR/libfprint-CS9711 | LGPL-2.1+。1500ms リトライパッチ付き |
| `sigma-file-manager` 2.2.0 | 公式debを再パッケージ (`pkgs/sigma-file-manager`) | GPL-3.0-or-later。Tauri製バイナリを autoPatchelf。デフォルトFM (nemo置換) |
| `sunshine` (JIS) | ../sunshine-nix から vendored (`pkgs/sunshine/`) | GPL-3.0-or-later + MIT (詳細と出典は `pkgs/sunshine/README.md`)。`main-desktop` でユーザーサービスとして起動 |
| quickshell パッチ | fedora-hyprtomic `files/gui-build/patches/` | upstream 修正が入ったら自動スキップ |

