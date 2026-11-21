-- VSCode 風サイドバー(左エクスプローラー)のトグル
local env = require("config.env")

local function toggle_explorer()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "snacks_picker_list" then
      vim.api.nvim_win_close(win, true)
      return
    end
  end
  local cwd = Snacks.git.get_root() or (vim.uv or vim.loop).cwd()
  Snacks.explorer({ cwd = cwd })
end

-- ripgrep が無い環境向けのフォールバック検索
-- snacks.picker.grep は rg 固定なので、内蔵の :vimgrep + quickfix で代替する
local function grep_fallback()
  vim.ui.input({ prompt = "Grep (内蔵検索): " }, function(input)
    if not input or input == "" then
      return
    end
    -- \V (very nomagic) でリテラル検索。区切りの / だけエスケープする
    local pattern = vim.fn.escape(input, "/")
    local wildignore = vim.o.wildignore
    vim.o.wildignore = wildignore .. ",.git/*,node_modules/*,.venv/*,dist/*"
    pcall(vim.cmd, ("silent! vimgrep /\\V%s/j **/*"):format(pattern))
    vim.o.wildignore = wildignore
    if #vim.fn.getqflist() == 0 then
      vim.notify("該当なし: " .. input, vim.log.levels.INFO, { title = "grep" })
      return
    end
    vim.cmd("copen")
    vim.notify_once(
      ("`rg` を導入すると高速な検索になります: %s"):format(env.install_hint("rg")),
      vim.log.levels.INFO,
      { title = "grep" }
    )
  end)
end

local function picker_grep()
  if env.has("rg") then
    Snacks.picker.grep()
  else
    grep_fallback()
  end
end

local function picker_git_files()
  if env.has("git") then
    Snacks.picker.git_files()
  else
    -- git が無い環境では通常のファイル検索にフォールバック
    Snacks.picker.files()
  end
end

local function picker_git_status()
  if env.has("git") then
    Snacks.picker.git_status()
  else
    env.notify_missing("git", "Git Status")
  end
end

local function git_browse()
  if env.has("git") then
    Snacks.gitbrowse()
  else
    env.notify_missing("git", "GitHub 連携")
  end
end

local function open_lazygit()
  if env.has("lazygit") then
    Snacks.lazygit()
  else
    env.notify_missing("lazygit", "lazygit")
  end
end

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    bigfile = { enabled = true },
    dashboard = require("plugins.snacks.dashboard"),
    explorer = { enabled = true },
    input = { enabled = true },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    -- 常駐負荷の削減: 見た目系(インデントガイド・スコープ強調・スムーズスクロール)
    -- は無効化。ハイライトは treesitter が担当する
    indent = { enabled = false },
    scope = { enabled = false },
    scroll = { enabled = false },
    -- SSH/CLI 環境では画像表示(ueberzugpp等)が使えないため無効
    image = { enabled = false },
    picker = {
      enabled = true,
      input = {
        keys = {
          -- 旧 telescope の <C-j>/<C-k> 操作を移植
          ["<C-j>"] = { "list_down", mode = { "i", "n" } },
          ["<C-k>"] = { "list_up", mode = { "i", "n" } },
        },
      },
    },
  },
  keys = {
    { "<leader>z",  function() Snacks.zen.zoom() end,           desc = "Toggle Zoom" },
    { "<leader>gB", git_browse,                                 desc = "Git Browse (GitHub)" },
    { "<leader>gg", open_lazygit,                               desc = "Lazygit" },
    { "<leader>n",  function() Snacks.notifier.show_history() end, desc = "Notification History" },
    { "[[",         function() Snacks.words.jump(-1) end,       desc = "Prev Reference" },
    { "]]",         function() Snacks.words.jump(1) end,        desc = "Next Reference" },
    { "<leader>sf", function() Snacks.picker.files() end,       desc = "Find Files" },
    { "<leader>sg", picker_grep,                                desc = "Grep" },
    { "<leader>e", toggle_explorer,                              desc = "エクスプローラー(サイドバー)開閉" },
    { "<leader>gS", picker_git_status,                          desc = "Git Status (Source Control)" },
    -- 旧 telescope のキーマップを snacks.picker に移植
    { "<leader>ff", function() Snacks.picker.files() end,       desc = "Find Files" },
    { "<leader>fg", picker_grep,                                desc = "Live Grep" },
    { "<leader>fb", function() Snacks.picker.buffers() end,     desc = "Buffers" },
    { "<leader>fh", function() Snacks.picker.help() end,        desc = "Help Tags" },
    { "<leader>gs", picker_git_files,                           desc = "Git Files" },
  },
}
