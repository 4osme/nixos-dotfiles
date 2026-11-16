-- 言語固有の設定を持たない汎用 LSP 設定。
-- 使いたい言語のサーバー名を `servers` に追加するだけ。
--
-- 通常の glibc Linux / macOS では mason が `~/.local/share/nvim/mason` へ
-- 自動インストールする。Termux と musl (Alpine 等) では mason の配布
-- バイナリが動かないため mason を組み込まず、PATH 上にあるサーバーだけを
-- 有効化する(無い場合は導入方法を通知するのみでエラーにはしない)。
--
-- 例: "ts_ls" (TypeScript/JS), "gopls" (Go), "solargraph" (Ruby),
--     "pyright" (Python), "clangd" (C/C++), "rust_analyzer" (Rust)
local env = require("config.env")

local servers = { "lua_ls" }

-- mason を使うかどうか(実行環境依存)
local use_mason = not env.is_termux and not env.is_musl

-- 各サーバーの導入方法ヒント用パッケージ名
local server_packages = {
  lua_ls = "lua-language-server",
}

local deps = {
  -- LSP capabilities (snippet 対応等) を cmp 経由で付与する
  "hrsh7th/cmp-nvim-lsp",
}
if use_mason then
  table.insert(deps, { "mason-org/mason.nvim", opts = {} })
  table.insert(deps, { "mason-org/mason-lspconfig.nvim", opts = { ensure_installed = servers } })
end

return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = deps,
  config = function()
    -- Neovim 0.11+ の新API (vim.lsp.config / vim.lsp.enable) を使用。
    -- 旧 require("lspconfig") / mason-lspconfig handlers は廃止済み。

    -- nvim-cmp の capabilities(snippet 等)を全サーバーへ適用
    vim.lsp.config("*", {
      capabilities = require("cmp_nvim_lsp").default_capabilities(),
    })

    -- 起動可能なサーバーだけ有効化する
    for _, server in ipairs(servers) do
      local ok, cfg = pcall(function()
        return vim.lsp.config[server]
      end)
      local cmd = ok and cfg and cfg.cmd and cfg.cmd[1] or nil
      local available = cmd and vim.fn.executable(cmd) == 1
      if available then
        vim.lsp.enable(server)
      else
        local msg = ("LSP `%s` は実行環境が見つからないため無効化しています"):format(server)
        if not use_mason then
          msg = msg .. "\n導入方法: " .. env.install_hint(server_packages[server] or server)
        end
        vim.notify(msg, vim.log.levels.INFO, { title = "nvim-lspconfig" })
      end
    end

    vim.diagnostic.config({})

    -- LSP がアタッチされたバッファでのみ有効なキーマップ
    -- (README.md「コードを読む・定義へジャンプ」と対応)
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
      callback = function(ev)
        local opts = function(desc)
          return { buffer = ev.buf, desc = desc }
        end
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts("定義へジャンプ"))
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts("宣言へジャンプ"))
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts("実装へジャンプ"))
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts("参照一覧"))
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts("ホバーでドキュメント表示"))
        -- rename は Neovim 標準の grn、コードアクションは gra を使用
      end,
    })
  end,
}
