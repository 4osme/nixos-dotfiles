---
name: nvim-verify
description: nvim設定を変更した後の検証バッテリー。lua/plugins/ や lua/config/、README、キーマップを変更したときに必ず使う。
---

# 検証バッテリー

変更後に順に実行し、**エラー・警告がゼロであること**を確認する。

## 1. プラグイン同期(依存の導入・削除の反映)

```bash
nvim --headless "+Lazy! sync" +qa 2>&1 | grep -iE "error|fail"
```

## 2. 起動・ロードエラーの確認

```bash
nvim --headless init.lua "+edit README.md" \
  "+lua vim.defer_fn(function() local m=vim.api.nvim_exec2('messages',{output=true}).output; io.stderr:write('MSG_LEN='..#m..'\n'..m..'\n'); vim.cmd('qa!') end, 8000)" 2>&1
```

`MSG_LEN=0`(または既知の情報メッセージのみ)であること。treesitter 由来の `range` エラーが出たら `lua/config/treesitter_compat.lua` の扱いを疑う。

## 3. LSP・遅延プラグインの動作

```bash
nvim --headless init.lua "+edit init.lua" \
  "+lua vim.defer_fn(function() io.stderr:write('LSP='..vim.inspect(vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients()))..'\n'); vim.cmd('qa!') end, 8000)"
```

- 期待するサーバーだけがアタッチすること(実行環境が無いサーバーは通知付きでスキップされるのが正)。
- 通知は snacks.notifier が横取りするため `:messages` に出ない。`require('snacks').notifier.get_history()` も確認する。
- `package.loaded["<プラグイン>"]` や `lazy.core.config().plugins[name]._.loaded` で遅延ロードの確認も可能(※headless では VeryLazy が発火しないため、`require('lazy').load({plugins={...}})` を明示的に呼ぶ)。

## 4. 起動時間

```bash
nvim --headless -u init.lua --startuptime /tmp/st.log +qa >/dev/null 2>&1; tail -1 /tmp/st.log
```

目安: ~20ms 台(想定外に伸びた場合は eager ロードされたプラグインを疑う)。

## 5. レイアウト・分割

```bash
nvim --headless init.lua "+lua vim.cmd('vsplit | vsplit'); vim.defer_fn(function() io.stderr:write('wins='..#vim.api.nvim_list_wins()..'\n'); vim.cmd('qa!') end, 1200)"
```

エディタ分割は自由（旧・単一画面制限は撤廃済み）。`wins=3` になること（通知用 float を除く）。

## 6. 依存が無い環境のフォールバック

```bash
# Termux 相当: mason が構成から外れ、起動がエラーにならないこと
TERMUX_VERSION=1 nvim --headless "+Lazy! install" +qa

# rg / cc 無し相当(PATH を絞る): treesitter のビルド・自動導入が無効化されること
PATH=/nonexistent timeout 30 nvim --headless --noplugin -u NONE \
  "+lua vim.opt.rtp:prepend(vim.fn.stdpath('config')); \
   local e=require('config.env'); assert(not e.has('cc')); \
   local s=dofile(vim.fn.stdpath('config')..'/lua/plugins/nvim-treesitter.lua'); \
   assert(s.build == nil and #s.opts.ensure_installed == 0); vim.cmd('qa!')"
```

- ripgrep が無い環境で `<leader>sg` が内蔵 `:vimgrep` にフォールバックし、`<leader>rr` が通知のみでエラーにならないこと。
- lazygit 自動導入は `env.can_run_prebuilt()`(glibc Linux/macOS)でのみ実行されること。
