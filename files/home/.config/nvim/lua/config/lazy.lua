-- Neovim 0.11 未満ではプラグインを読み込まず、init.lua の基本設定のみで起動する。
-- (ディストリビューション付属の古い nvim でも「基本機能だけ」で編集できるようにする)
if vim.fn.has("nvim-0.11") ~= 1 then
  vim.schedule(function()
    vim.notify(
      "Neovim 0.10 以下を検出したため、プラグインを無効化して基本設定のみで起動します",
      vim.log.levels.WARN,
      { title = "nvim" }
    )
  end)
  return
end

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
-- mapleader / maplocalleader は init.lua 側で設定済み
require("lazy").setup({
  spec = {
    -- import your plugins
    { import = "plugins" },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "tokyonight", "habamax" } },
  -- automatically check for plugin updates
  checker = { enabled = true, notify = false },
})
