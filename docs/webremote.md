# Web ブラウザでのリモート操作 (main-desktop)

Web ブラウザから main-desktop をリモート操作するための構成。
Sunshine (ストリーミングホスト) + moonlight-web-stream (ブラウザ Moonlight クライアント)
+ Cloudflare Tunnel (外部アクセス) で構成され、すべて手動起動する。

## Nix 定義

| 定義 | 場所 | 内容 |
|---|---|---|
| `sunshine` パッケージ | `pkgs/sunshine/` | `../sunshine-nix` から vendored、JIS キーボードパッチ付き (`overlays/default.nix` で `pkgs.sunshine` を override) |
| `moonlight-web-stream` パッケージ | `pkgs/moonlight-web-stream/` | upstream + `../moonlight-web-stream/patches/` |
| モジュール | `modules/environments/main-desktop/sunshine.nix` / `moonlight-web.nix` | `sunshine`, `cloudflared`, `moonlight-web-stream` をインストール |
| ユーザーサービス | `home/sunshine.nix` / `home/moonlight-web.nix` | systemd ユニット定義 (`home/default.nix` が main-desktop のときだけ import) |
| 補助スクリプト | `files/home-main-desktop/.local/bin/sunshine-session` | 仮想モニタの作成/削除とサービス起停を一括で行う |

## systemd ユニット

| ユニット | 内容 |
|---|---|
| `sunshine.service` | Sunshine 本体 (`Restart = on-failure`) |
| `cloudflared-tunnel.service` | cloudflared トンネル (`EnvironmentFile = ~/.config/cloudflared/tunnel.env`) |
| `moonlight-web-stream.service` | Web サーバー (`ExecStart = web-server`) |

いずれも `Install.WantedBy` を持たないため自動起動しない。

## 起動 / 停止

Hyprland セッション (端末または SSH) から:

```sh
# 起動 (HEADLESS-1 FullHD + Sunshine + Cloudflare Tunnel)
sunshine-session start --tunnel
systemctl --user start moonlight-web-stream

# 停止
systemctl --user stop moonlight-web-stream
sunshine-session stop --tunnel
```

`--tunnel` を省略すると Sunshine のみの操作になる。Cloudflare Tunnel を
個別に操作する場合は `systemctl --user start/stop cloudflared-tunnel`。
`sunshine-session status` で現在の状態を確認できる。

## 仮想モニタ (HEADLESS-1)

`sunshine-session start` は次の順で動く:

1. Hyprland に `HEADLESS-1` (1920x1080@60 の仮想出力) を作成する。
2. `~/.config/sunshine/sunshine.conf` (unmanaged) の `capture` / `output_name` を
   `wlr` / `HEADLESS-1` に切り替える。
3. `sunshine.service` を起動する。
4. `~/.config/hypr/host.lua` の 1080p プロファイルを適用し、
   HDMI-A-1 / HDMI-A-2 を無効化して仮想出力を 0x0 に置く。

`sunshine-session stop` は Sunshine を止めた後、通常のモニター構成
(`monitors.lua` の HDMI-A-1 + HDMI-A-2) に戻して `HEADLESS-1` を削除する。
状態は `$XDG_RUNTIME_DIR/sunshine-hypr-display/` に置かれ、
`~/.config/sunshine/hypr-stream-display.py` がクライアント接続/切断時にも
同じプロファイルを切り替える。クライアント切断時は物理モニターへ戻り、
`HEADLESS-1` は次回接続のために画面外 (10000x0) へ退避する。
完全な削除は `sunshine-session stop` が行う。

## Cloudflare Tunnel のトークン設定

トークンはリポジトリに含めない。初回だけ次のファイルを作る (`0600`):

```sh
install -d -m 700 ~/.config/cloudflared
printf 'TUNNEL_TOKEN=%s\n' '<token>' > ~/.config/cloudflared/tunnel.env
chmod 600 ~/.config/cloudflared/tunnel.env
```

## moonlight-web-stream のデータ

設定とデータは `~/.local/state/moonlight-web-stream/server/` に置かれる。
初回に設定ファイルが必要なら:

```sh
mkdir -p ~/.local/state/moonlight-web-stream
cd ~/.local/state/moonlight-web-stream
web-server config generate
```

Web UI は `http://<host>:8080/`。Cloudflare Tunnel 経由でも同じポートへ
接続する。WebRTC を直接使う場合は UDP のポート範囲も開ける必要がある。
