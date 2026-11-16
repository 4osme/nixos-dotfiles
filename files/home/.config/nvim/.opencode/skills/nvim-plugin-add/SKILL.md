---
name: nvim-plugin-add
description: このnvim設定にプラグインを追加・変更する手順。新規プラグイン、LSPサーバー、treesitterパーサー、キーマップ追加のときに使う。
---

# プラグイン追加手順

## 1. spec ファイルを作る

`lua/plugins/<plugin名>.lua` を1ファイル=1プラグインで作成(lazy.nvim が自動 import)。必要な言語固有プラグインは作らないこと(AGENTS.md の「汎用設定を維持」参照)。

```lua
return {
  "作者/プラグイン名",
  -- 遅延ロードを指定(keys/cmd/event/ft のいずれか)
  event = { "BufReadPre", "BufNewFile" }, -- 例
  opts = {}, -- lazy が require("プラグイン名").setup(opts) を呼ぶ
}
```

チェックリスト:
- `dependencies` に子プラグインを書く場合、**setup が必要な子には `opts = {}` を付ける**(付けないと setup が呼ばれない)。
- `opts` が効いているかは `require("プラグイン名").setup` のシグネチャで確認(treesitter のように `main` モジュールが opts を無視する例がある。その場合は `config = function(_, opts) ... end` を明示)。
- 言語別処理(LSP/パーサー/デバッガ)は専用ファイルを作らず、拡張ポイントへ1行追加:
  - LSP: `lua/plugins/nvim-lspconfig.lua` の `servers`
  - パーサー: `lua/plugins/nvim-treesitter.lua` の `ensure_installed`
  - デバッガ: `lua/plugins/nvim-dap.lua` の dependencies

## 2. 検証

`.opencode/skills/nvim-verify/SKILL.md` のバッテリーを実行。

## 3. ドキュメント同期

- キーマップを追加/変更したら `README.md` の対応表を更新(desc と文言を揃える)。
- `<leader>X` に新グループを作ったら `lua/plugins/which-key.nvim.lua` の `spec` にグループ名(日本語)を追加。
- プラグインの重要な前提(要外部ツール等)は README のセットアップ章に追記。
