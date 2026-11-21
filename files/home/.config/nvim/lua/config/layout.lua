-- VSCode 風レイアウトの支援設定
-- ・ウィンドウ間移動を Ctrl+hjkl で
-- ・リサイズ系キーマップ
-- エディタ特化方針に伴い、ターミナル用に設けていた「エディタ単一画面」制限は撤廃。
-- 通常の分割編集をそのまま行える。

-- ==============================
-- ウィンドウ間移動（tmux 風・CLI 向け）
-- ==============================
local nav_keys = {
  { "<C-h>", "<C-w>h", "左のウィンドウへ" },
  { "<C-j>", "<C-w>j", "下のウィンドウへ" },
  { "<C-k>", "<C-w>k", "上のウィンドウへ" },
  { "<C-l>", "<C-w>l", "右のウィンドウへ" },
}
for _, k in ipairs(nav_keys) do
  vim.keymap.set("n", k[1], k[2], { silent = true, desc = k[3] })
end

-- ==============================
-- ウィンドウ操作
-- ==============================
vim.keymap.set("n", "<leader>wo", "<cmd>only<CR>", { silent = true, desc = "単一画面に戻す" })
vim.keymap.set("n", "<leader>w=", "<C-w>=", { silent = true, desc = "ウィンドウ幅を均等化" })
vim.keymap.set("n", "<leader>wd", "<C-w>q", { silent = true, desc = "ウィンドウを閉じる" })
vim.keymap.set("n", "<leader>w+", "<cmd>resize +2<CR>", { silent = true, desc = "ウィンドウ高さを+2" })
vim.keymap.set("n", "<leader>w-", "<cmd>resize -2<CR>", { silent = true, desc = "ウィンドウ高さを-2" })
vim.keymap.set("n", "<leader>w>", "<cmd>vertical resize +5<CR>", { silent = true, desc = "ウィンドウ幅を+5" })
vim.keymap.set("n", "<leader>w<", "<cmd>vertical resize -5<CR>", { silent = true, desc = "ウィンドウ幅を-5" })

-- ==============================
-- ターミナル（右カラム）の操作性
-- ==============================
-- ターミナルモードからも jk / Esc で抜ける（shell 内の Esc は jk で回避）
vim.keymap.set("t", "jk", "<C-\\><C-n>", { silent = true, desc = "ターミナルからノーマルモードへ" })
