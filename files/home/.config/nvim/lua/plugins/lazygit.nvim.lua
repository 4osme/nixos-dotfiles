-- nvim v0.8.0
-- lazygit バイナリが無い環境では、キー押下時に導入方法を通知する
-- (自動導入は lua/config/lazygit.lua。Termux/musl では手動導入が必要)
local env = require("config.env")

return {
  "kdheepak/lazygit.nvim",
  lazy = true,
  cmd = {
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },
  -- optional for floating window border decoration
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  -- setting the keybinding for LazyGit with 'keys' is recommended in
  -- order to load the plugin when the command is run for the first time
  keys = {
    {
      "<leader>lg",
      function()
        if not env.has("lazygit") then
          env.notify_missing("lazygit", "lazygit")
          return
        end
        vim.cmd("LazyGit")
      end,
      desc = "LazyGit",
    },
  },
}
