# Web ブラウザでのリモート操作 (main-desktop)

main-desktop は Sunshine ストリーミングホストを提供する。
moonlight-web-stream は別環境で管理し、このホストには導入しない。
Cloudflare Tunnel も別環境で管理し、このホストには導入しない。
接続先の設定は別途管理する。

## Nix 定義

| 定義 | 場所 | 内容 |
|---|---|---|
| `sunshine` パッケージ | `pkgs/sunshine/` | `../sunshine-nix` から vendored、JIS キーボードパッチ付き (`overlays/default.nix` で `pkgs.sunshine` を override) |
| モジュール | `hosts/main-desktop/sunshine.nix` | `sunshine` をインストール |
| ユーザーサービス | `modules/home-manager/sunshine.nix` | systemd ユニット定義 (`hosts/main-desktop/home.nix` が import) |
| 補助スクリプト | `files/home-main-desktop/.local/bin/sunshine-session` | 仮想モニタの作成/削除とサービス起停を一括で行う |

## systemd ユニット

| ユニット | 内容 |
|---|---|
| `sunshine.service` | Sunshine 本体 (`Restart = on-failure`) |

いずれも `Install.WantedBy` を持たないため自動起動しない。

## 起動 / 停止

Hyprland セッション (端末または SSH) から:

```sh
# 起動 (HEADLESS-1 FullHD + Sunshine)
sunshine-session start

# 停止
sunshine-session stop
```

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
3. セッション開始時に有効だった物理出力の復帰を確認し、`HEADLESS-1` を削除する。
   復帰できなければ状態を残してエラー終了し、再実行できる。

これで通常の DMS 定義レイアウトに戻る。`outputs.lua` がまだ無い場合は
`hyprland.lua` の自動検出 (preferred / auto) になるので、初回は DMS の
Displays 設定を一度適用しておく。`sunshine.conf` の `output_name` は
`HEADLESS-1` のまま残るため、次回も `sunshine-session start` から始める。

クライアント単位の 1080p / native 切替は `~/.config/sunshine/hypr-stream-display.py`
が行う（Sunshine の prep-cmd に登録されている場合）。こちらもセッション中は
`session.active` を尊重し、切断時に物理モニタを勝手に戻さない。
