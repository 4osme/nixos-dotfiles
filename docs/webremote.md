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

## 仮想モニタ (HEADLESS-1) とモニタ切替

`sunshine-session start` は次の順で動く:

1. Hyprland に `HEADLESS-1` (1920x1080@60 の仮想出力) を作成する。
2. `~/.config/sunshine/sunshine.conf` (unmanaged) の `capture` / `output_name` を
   `wlr` / `HEADLESS-1` に切り替える。
3. `$XDG_RUNTIME_DIR/sunshine-hypr-display/session.active` を書く。
4. `hyprctl reload` で `~/.config/hypr/host.lua` のセッションプロファイルを適用する。
   HEADLESS-1 を 0x0 / 1080p60 に置き、それ以外の出力 (HDMI-A-1 / HDMI-A-2 など) を
   すべて無効化する。
5. `sunshine.service` を起動/再起動する。

クライアントの接続・切断ではこのレイアウトを変えない。切断しても
HEADLESS-1 と「物理出力オフ」を維持する（4K パネルを点けるとストリームが
重くなるため）。`session.active` は `sunshine-session stop` まで残る。

`sunshine-session stop` は Sunshine を止めた後、

1. `session.active` と `hypr-stream-display.py` の状態を消す。
2. `hyprctl reload` で Dux Shell が書く `~/.config/hypr/dms/outputs.lua` を再適用する。
3. reload で復帰しなかった物理出力を、記憶した mode / position / scale で
   明示的に戻す。
4. `HEADLESS-1` を削除する。

これで通常の DMS 定義レイアウトに戻る。`outputs.lua` がまだ無い場合は
`hyprland.lua` の自動検出 (preferred / auto) になるので、初回は DMS の
Displays 設定を一度適用しておく。`sunshine.conf` の `output_name` は
`HEADLESS-1` のまま残るため、次回も `sunshine-session start` から始める。

クライアント単位の 1080p / native 切替は `~/.config/sunshine/hypr-stream-display.py`
が行う（Sunshine の prep-cmd に登録されている場合）。こちらもセッション中は
`session.active` を尊重し、切断時に物理モニタを勝手に戻さない。

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
