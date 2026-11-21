vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.lazy")
require("config.layout")
require("config.lazygit")
require("config.terminal").setup()
require("config.session").setup()

vim.opt.number = true
-- ステータスラインは画面最下部に1本化(lualineのglobalstatusと連動)。
-- 横の窓境が白線(WinSeparator)になり、モード表示はlualine側に一本化する
vim.opt.laststatus = 3
vim.opt.showmode = false
-- 相対行番号は無効化: 有効化するとカーソル行だけ絶対行番号・他は相対距離に
-- なるため「1,2,3…と順番に並ばない」表示になる。VSCode風の絶対行番号のみにする
vim.opt.relativenumber = false
vim.opt.cursorline = true
vim.opt.helplang = 'ja'
vim.opt.clipboard = "unnamedplus"
-- マウスはクリックでのカーソル移動とホイールスクロールのみ許可する。
-- 'v' を外すとドラッグ選択によるビジュアルモード開始が無効になる
-- (誤クリックで選択がついてくるのを防ぐ。選択は v キーで開始する)
vim.opt.mouse = "ni"
vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("n", "<Esc><Esc>", ":nohlsearch<CR>", { silent = true })

-- 背景を透明にするための設定
local groups = { "Normal", "NonText", "NormalNC", "NormalSB" }

for _, group in ipairs(groups) do
    -- nvim_set_hl(名前空間, グループ名, 設定値のテーブル)
    -- 0 はグローバルな名前空間を指します
    vim.api.nvim_set_hl(0, group, {
        bg = "none",    -- GUI用の背景色をなしに設定
        ctermbg = "none" -- ターミナル用の背景色をなしに設定
    })
end

vim.keymap.set('n', '<Leader>cf', '<Cmd>let @+ = expand("%")<CR>', { desc = "相対パスをコピー" })
vim.keymap.set('n', '<Leader>cF', '<Cmd>let @+ = expand("%:p")<CR>', { desc = "フルパスをコピー" })


-- ==========================================
-- インデントの基本設定
-- ==========================================

-- 改行時に前の行のインデントを継続します
-- 引用元: :help 'autoindent'
vim.opt.autoindent = true

-- C言語に近い言語（Java, Python, Luaなど）で、
-- コードの構造（{ } など）を解釈して賢くインデントします
-- 引用元: :help 'smartindent'
vim.opt.smartindent = true

-- タブ文字（Tabキー）をスペースに変換します
-- 多くのプログラミング言語での推奨設定です
vim.opt.expandtab = true

-- キーボードのTabキーを押した時に入力されるスペースの数
vim.opt.tabstop = 2

-- 自動インデントやコマンド（>>）で操作される際のインデントの幅
vim.opt.shiftwidth = 2

-- タブや改行などの不可視文字を表示して、インデントのズレを確認しやすくします
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.api.nvim_create_autocmd({ "WinEnter", "FocusGained", "BufEnter" }, {
	pattern = "*",
	command = "checktime",
})
