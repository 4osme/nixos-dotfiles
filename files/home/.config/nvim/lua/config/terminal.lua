-- 汎用シェル(TERMINAL)の自前管理
-- エディタ特化方針のため、opencode 等のエージェント画面は撤去済み。
-- 配置は固定:
--   シェル : 右カラム全高(約33%幅)
-- 開くたびにサイズを掛け直すため、手動リサイズ後も次回開閉で仕様に戻る。
local M = {}

local SHELL_WIDTH_RATIO = 0.325

-- ターミナル窓の視認性: ベースより少し明るい背景 + 白い境界線
-- (エディタ側は透明のまま。colorscheme再読込に追従させる)
local function lighten(hex, amt)
  local r = tonumber(hex:sub(2, 3), 16)
  local g = tonumber(hex:sub(4, 5), 16)
  local b = tonumber(hex:sub(6, 7), 16)
  if not (r and g and b) then return hex end
  local function up(v)
    return math.floor(v + (255 - v) * amt + 0.5)
  end
  return string.format("#%02x%02x%02x", up(r), up(g), up(b))
end

local function apply_highlights()
  local base = "#1a1b26" -- tokyonight night の bg。取得できなければこれを使う
  local ok, tc = pcall(require, "tokyonight.colors")
  if ok and tc.setup then
    local pal_ok, pal = pcall(tc.setup)
    if pal_ok and type(pal) == "table" and pal.bg then
      base = pal.bg
    end
  end
  vim.api.nvim_set_hl(0, "TermBright", { bg = lighten(base, 0.12) })
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#ffffff", bg = "NONE" })
end

local slot = { cmd = vim.o.shell, name = "TERMINAL", buf = nil, win = nil, prev = nil }

local function is_open()
  return slot.win ~= nil and vim.api.nvim_win_is_valid(slot.win)
end

-- プロセス終了時は窓を畳み、スロットを捨てて次回まっさら作り直す
local function on_term_close()
  return vim.schedule_wrap(function()
    if is_open() then
      pcall(vim.api.nvim_win_close, slot.win, true)
    end
    if slot.buf and vim.api.nvim_buf_is_valid(slot.buf) then
      pcall(vim.api.nvim_buf_delete, slot.buf, { force = true })
    end
    slot.buf, slot.win, slot.prev = nil, nil, nil
  end)
end

local function ensure_buf()
  if slot.buf and vim.api.nvim_buf_is_valid(slot.buf) then
    return slot.buf
  end
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_create_autocmd("TermClose", { buffer = buf, callback = on_term_close() })
  -- ジョブの起動(termopen)は窓を開いてから行う。ここでは器だけ用意する。
  slot.buf = buf
  return buf
end

local function decorate(win, name)
  pcall(vim.api.nvim_set_option_value, "number", false, { win = win })
  pcall(vim.api.nvim_set_option_value, "relativenumber", false, { win = win })
  pcall(vim.api.nvim_set_option_value, "winbar", " " .. name .. " ", { win = win })
  -- 窓だけ少し明るくする(エディタは透明のまま)
  pcall(vim.api.nvim_set_option_value, "winhighlight", "Normal:TermBright", { win = win })
end

local function open_shell()
  if is_open() then return end
  local buf = ensure_buf()
  slot.prev = vim.api.nvim_get_current_win()
  -- タブ全体の右に分割 → 常に右カラム全高になる(フォーカス位置に依存しない)
  vim.cmd("botright vsplit")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  if vim.bo[buf].buftype ~= "terminal" then
    -- 通常の ~/.zshrc で起動する
    local job = vim.fn.termopen(slot.cmd)
    if not job or job <= 0 then
      vim.notify("シェルの起動に失敗しました", vim.log.levels.ERROR)
      pcall(vim.api.nvim_win_close, win, true)
      return
    end
  end
  vim.api.nvim_win_set_width(win, math.floor(vim.o.columns * SHELL_WIDTH_RATIO))
  slot.win = win
  decorate(win, slot.name)
  pcall(vim.cmd, "startinsert")
end

local function close_slot()
  if not is_open() then return end
  local win = slot.win
  slot.win = nil
  pcall(vim.api.nvim_win_close, win, true)
  -- 閉じる前の窓へフォーカスを戻す(有効な場合のみ)
  if slot.prev and vim.api.nvim_win_is_valid(slot.prev) then
    pcall(vim.api.nvim_set_current_win, slot.prev)
  end
  slot.prev = nil
end

local function is_shell_win(win)
  if slot.win == win then return true end
  if vim.api.nvim_win_is_valid(win) and slot.buf then
    return vim.api.nvim_win_get_buf(win) == slot.buf
  end
  return false
end

-- 右カラム全高に汎用シェルを開閉(シェルにしか触れない)
function M.toggle_shell()
  if is_open() then
    close_slot()
  else
    open_shell()
  end
end

-- フォーカス中のシェルだけを閉じる(ターミナルモードの Ctrl+\ 用)
-- 自前窓でなければシェルを開く。
function M.toggle_focused()
  if is_shell_win(vim.api.nvim_get_current_win()) then
    close_slot()
  else
    M.toggle_shell()
  end
end

function M.setup()
  apply_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("TerminalHl", { clear = true }),
    callback = apply_highlights,
  })
  vim.keymap.set({ "n", "i" }, [[<C-\>]], M.toggle_shell, { silent = true, desc = "右カラムにシェル開閉" })
  vim.keymap.set("t", [[<C-\>]], M.toggle_focused, { silent = true, desc = "フォーカス中のターミナルだけ閉じる" })
end

return M
