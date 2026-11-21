# AGENTS.md — このリポジトリでの作業ルール(エージェント向け)

## 環境の前提

- **SSH 接続の CLI 専用リモート(kvm)環境**。GUI・ブラウザ・ローカルクリップボード(OSC52未対応)は使えない。
- **システム変更は禁止**(パッケージ追加、`/etc` 配下の変更など)。必要なツールは `~/.local/bin` や mason(`~/.local/share/nvim/mason`)、nvim の初回起動時自動導入(lazygit)で賄う。
- この kvm は作業用。成果物はリモートリポジトリに push 後、別環境へデプロイする。
- Neovim **0.12.5** / lazy.nvim。`rm` コマンドは権限で拒否されるため **`git rm` を使う**。

## ファイル構成

| パス | 役割 |
|---|---|
| `init.lua` | エントリーポイント(基本オプション・キーマップのみ) |
| `lua/config/lazy.lua` | lazy.nvim のブートストラップ(0.11 未満はプラグイン無効の基本モード) |
| `lua/config/env.lua` | 実行環境・外部ツールの検出(Termux/musl/glibc、rg/cc/lazygit/git 等) |
| `lua/config/layout.lua` | VSCode風レイアウト(ウィンドウ移動・リサイズ。分割は自由) |
| `lua/config/lazygit.lua` | lazygit 自動導入(対応環境のみ。Termux/musl では手動案内) |
| `lua/config/session.lua` | セッション管理(Neovim 内蔵のみ。fzf 等は不要) |
| `lua/config/terminal.lua` | 右カラム汎用ターミナルの操作(エージェント連携は撤去済み) |
| `lua/config/treesitter_compat.lua` | Neovim 0.12 × nvim-treesitter(legacy master) 互換シム |
| `lua/plugins/*.lua` | プラグイン設定(1ファイル=1プラグイン。lazy.nvim が自動 import) |
| `lua/plugins/snacks/` | snacks.nvim(spec と dashboard) |

## 重要な制約・パターン

- **エディタ特化・軽量方針**: nvim 内からターミナルや AI エージェントを積極的に呼び出す構成にはしない。ターミナルは右カラムの汎用シェル(`terminal.lua`)のみ。opencode 等のエージェント連携は撤去済みで、再導入しない。
- **起動時間・常駐負荷を優先**: `lazy = false` を安易に使わない。`event`/`keys`/`cmd`/`ft` での遅延を徹底する(oil/lualine は遅延化済み)。snacks の見た目系モジュール(indent/scope/scroll)は無効化済み。
- **汎用設定を維持**: 言語固有の LSP・パーサー・ft-plugin・デバッガを追加しない。言語サポートは拡張ポイントのみ: LSP → `lua/plugins/nvim-lspconfig.lua` の `servers`、パーサー → `nvim-treesitter.lua` の `ensure_installed`、アダプタ → `nvim-dap.lua`。
- treesitter は `branch = "master"`(legacy)固定。main branch に移行するときは `treesitter_compat.lua` の扱いも見直すこと。
- lazy-loading 規約: `keys`/`cmd`/`event`/`ft` で可能な限り遅延。deps に `opts = {}` がないと setup が呼ばれない点に注意。`opts` は内部で `require(<plugin名>).setup(opts)` を呼ぶ(モジュール名と setup の互換を確認すること。過去に treesitter で `opts` が無視される事故あり)。
- LSP は実行環境チェック付き `vim.lsp.enable`(`nvim-lspconfig.lua` を踏襲)。
- **外部依存は能力検出で吸収**: 外部ツール前提の機能を追加するときは `lua/config/env.lua` の検出を使い、無い環境では「機能だけ無効化+導入方法の通知」または内蔵機能へのフォールバックを必ず実装する(起動・編集でエラーを出さない)。自動ダウンロードは `env.can_run_prebuilt()` が true の環境(glibc Linux/macOS)のみで行う。
- **Neovim 0.11 未満は基本モード**: `lua/config/lazy.lua` が起動時にバージョンを判定し、プラグインを読み込まず `init.lua` の基本設定だけで動く。
- コメント・`desc`・README は**日本語**で書く。既存スタイル(lazy.nvim spec 形式)に倣う。
- キーマップの追加・変更をしたら **README.md の該当行を必ず更新**。which-key のグループ名(`which-key.nvim.lua`)とも整合させる。
- `lazy-lock.json` は git 管理下・バージョン固定に使用。`:Lazy! sync` 後にコミット対象になる。

## 検証(必須)

変更後は必ず headless で検証する(詳細は `.opencode/skills/nvim-verify/SKILL.md`):

```bash
nvim --headless "+Lazy! sync" +qa                                   # プラグイン同期
nvim --headless init.lua "+edit README.md" "+lua ..."               # 起動エラー・messages 確認
nvim --headless -u init.lua --startuptime /tmp/st.log +qa           # 起動時間
```

> OS 付属の nvim が 0.11 未満の場合は「基本モードの起動確認」しかできない。プラグイン込みの検証は 0.11+ の nvim バイナリ(`~/.local/bin` 等)で行うこと。

## スキル

- `.opencode/skills/nvim-plugin-add/SKILL.md` — プラグイン追加・言語サポート拡張の手順
- `.opencode/skills/nvim-verify/SKILL.md` — 変更後の検証バッテリー
