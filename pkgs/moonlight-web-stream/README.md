# moonlight-web-stream

`main-desktop` 専用のブラウザ Moonlight クライアント。upstream
(`MrCreativ3001/moonlight-web-stream`) のソースを取得し、`../moonlight-web-stream`
で開発したパッチを当ててビルドする (sunshine と同じ方式)。

## 固定しているもの

| 項目 | 値 |
|---|---|
| upstream | `a27f9126248fee88cad37fac7ebaec72bf8b2de0` (v3 prerelease) |
| moonlight-common-rust | `cc7ec8c3b3063742f4941500dcb78650bd0a9b98` |
| フロントエンド | Node 26 + webpack + ubrn 0.31.0-3 |
| WASM | wasm-bindgen-cli 0.2.128 (`Cargo.wasm.toml` の固定値) |

## パッチ

`patches/` は `../moonlight-web-stream/patches/` の写し。

- `0001-streaming-experiments.patch` — relay/queue、WebSocket、JIS 以外の
  ストリーミング実験 (元 `ref-streaming-experiments.patch` から docker/ を除外)
- `0002-jis-keyboard.patch` — JIS キーボード入力
- `0003-host-settings.patch` — ホストごとの設定上書き
- `0004-moonlight-common-av1.patch` — moonlight-common-rust の AV1 選択
- `0005-moonlight-common-stall-timeout.patch` — 音声/映像の停止タイムアウト
- `0006-ts-symbol-template.patch` — TS 5.9 の symbol テンプレートエラー修正

`0001`〜`0003` は upstream に、`0004`/`0005` は `moonlight-common-rust` に適用する。

## ビルドの注意

- upstream は `moonlight-common-rust` を git 依存にしているため、パッチで
  ローカルパス (`rust_modules/moonlight-common-rust`) に切り替えている。
- フロントエンドは `ubrn` で `web/uniffi` と `web/api_bindings.ts` を生成してから
  webpack する。Nix では git checkout できないので、`moonlight-common-rust` は
  `fetchFromGitHub` で用意し、cargo の vendor ディレクトリを自前で結合している。
- `npm run build` の prebuild は実行せず、`preBuild` で生成処理を行い、
  `buildPhase` で webpack だけを実行する (`buildNpmPackage` の postPatch は
  npm-deps にしか適用されないため)。

## main-desktop での起動

```sh
systemctl --user start moonlight-web-stream
systemctl --user stop moonlight-web-stream
```

設定とデータは `~/.local/state/moonlight-web-stream/server/` に置かれる。
