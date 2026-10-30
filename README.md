# NixOS dotfiles

NixOSとHomeManagerを使ったホストの宣言的なシステム管理とdistrobox/Vyprを使った非宣言的なゲスト環境のハイブリッド型を目指したdotfiles。

## 独自パッケージの出典

| パッケージ | 出典 | 備考 |
|---|---|---|
| `hyprbind` 0.1.4 | ry2x/HyprBind | MIT/OFL。ソースからビルド |
| `hypremoji` 1.3.0 | Musagy/hypremoji | AUR `hypremoji` と同一 upstream。upstream に Cargo.lock が無いため生成済み lock を `pkgs/hypremoji/` に固定 |
| `fcitx5-mozkey` 0.7.6 | Masterisk-F/fcitx-mozkey | BSD-3/Apache-2.0/LGPL-2.1。ソースから Bazel ビルド (`pkgs/mozkey/`, 詳細は同ディレクトリの README)
| `vypr` 0.5.0 | Amzi-01/Vypr | Unlicense。4 パッチ + `vypr-setup.exe` 同梱 |
| `sddm-hyprtomic-theme` | Keyitdev/sddm-astronaut-theme + `files/sddm-theme` | GPL-3.0 |
| `google-sans-flex` | ririko66z/dots-hyprland COPR RPM | OFL。Fedora の gui-04-fonts.sh と同じ成果物 |
| `libfprint-cs9711` 1.94.10 | archeYR/libfprint-CS9711 | LGPL-2.1+。1500ms リトライパッチ付き |
| `sunshine` (JIS) | ../sunshine-nix から vendored (`pkgs/sunshine/`) | GPL-3.0-or-later + MIT (詳細と出典は `pkgs/sunshine/README.md`)。`main-desktop` で手動起動 (`sunshine-session start`) |
| `moonlight-web-stream` | upstream + `../moonlight-web-stream` のパッチ (`pkgs/moonlight-web-stream/`) | GPL-3.0-or-later。`main-desktop` 専用、手動起動 (`systemctl --user start moonlight-web-stream`) |

