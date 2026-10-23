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
| `sunshine` (JIS) | ../sunshine-nix から vendored (`pkgs/sunshine/`) | GPL-3.0-or-later + MIT (詳細と出典は `pkgs/sunshine/README.md`)。`main-desktop` で手動起動 (`sunshine-session start`) |
| `moonlight-web-stream` | upstream + `../moonlight-web-stream` のパッチ (`pkgs/moonlight-web-stream/`) | GPL-3.0-or-later。`main-desktop` 専用、手動起動 (`systemctl --user start moonlight-web-stream`) |
| `serein` | `ViceVerse-cz/Serein` の flake input | MIT/Apache-2.0。Native Discord クライアント。`SUPER + D` で起動 (Vesktop は移行までのフォールバック) |
| quickshell パッチ | fedora-hyprtomic `files/gui-build/patches/` | upstream 修正が入ったら自動スキップ |

Serein は upstream の flake をそのまま input として使う (`serein.url`)。
上流は nixos-unstable + Rust 1.98.1 を固定しており、このリポジトリの
nixpkgs 26.05 (Rust 1.95) ではビルドできないため、`inputs.nixpkgs` は
follow させていない。Hyprland の `SUPER + D` は `serein` を起動する。

## main-desktop: ストリーミング（手動起動）

Sunshine、Cloudflare Tunnel、moonlight-web-stream は自動起動しない。
ログイン後の Hyprland セッションで、必要なものだけ手動で起動する。

```sh
# 起動
sunshine-session start --tunnel
systemctl --user start moonlight-web-stream

# 停止
systemctl --user stop moonlight-web-stream
sunshine-session stop --tunnel
```

`--tunnel` を付けない場合は Sunshine だけを開始/停止し、Cloudflare Tunnel は
`systemctl --user start/stop cloudflared-tunnel` で個別に操作する。

### Sunshine の仮想ディスプレイ

`sunshine-session start` は次の順で動く:

1. Hyprland に `HEADLESS-1`（1920x1080@60 の仮想出力）を作成する。
2. `~/.config/sunshine/sunshine.conf` の `capture` / `output_name` を
   `wlr` / `HEADLESS-1` に切り替える。
3. Sunshine のユーザーサービスを起動する。
4. `~/.config/hypr/host.lua` の 1080p プロファイルを適用し、
   HDMI-A-1 / HDMI-A-2 を無効化して仮想出力を 0x0 に置く。

`sunshine-session stop` は Sunshine を止め、通常のモニター構成
（`monitors.lua` の HDMI-A-1 + HDMI-A-2）へ戻して `HEADLESS-1` を削除する。
状態は `$XDG_RUNTIME_DIR/sunshine-hypr-display/` に置かれ、
`hypr-stream-display.py` がクライアント接続/切断時にも同じプロファイルを
切り替える。クライアント切断時は物理モニターへ戻り、`HEADLESS-1` は次の
接続のために画面外 (10000x0) へ退避する。完全に削除するのは
`sunshine-session stop`。

### Cloudflare Tunnel

トークンはリポジトリに含めない。初回だけ次を作る（`0600`）:

```sh
install -d -m 700 ~/.config/cloudflared
printf 'TUNNEL_TOKEN=%s\n' '<token>' > ~/.config/cloudflared/tunnel.env
chmod 600 ~/.config/cloudflared/tunnel.env
```

### moonlight-web-stream

設定とデータは `~/.local/state/moonlight-web-stream/server/` に置かれる。
初回に設定ファイルが必要なら:

```sh
mkdir -p ~/.local/state/moonlight-web-stream
cd ~/.local/state/moonlight-web-stream
web-server config generate
```

Web UI は `http://<host>:8080/`。Cloudflare Tunnel 経由でも同じポートへ
接続する。WebRTC を直接使う場合は UDP のポート範囲も開ける必要がある。

