-- セッション管理(Neovim 内蔵のみ)
--
-- 以前は nvim-possession + fzf-lua を使っていたが、fzf バイナリが必須で
-- Termux などに入れにくかった。同じ操作感を vim.ui.select / vim.ui.input と
-- :mksession だけで実装し、外部依存を無くしている。

local M = {}

local dir = vim.fn.stdpath("state") .. "/sessions"

-- 最後に開いた/保存したセッション名(<leader>su の上書き先)
local current = nil

local function session_file(name)
  return dir .. "/" .. name .. ".vim"
end

local function list_sessions()
  vim.fn.mkdir(dir, "p")
  local names = {}
  for _, f in ipairs(vim.fn.glob(dir .. "/*.vim", false, true)) do
    names[#names + 1] = vim.fn.fnamemodify(f, ":t:r")
  end
  table.sort(names)
  return names
end

local function save_as(name)
  name = vim.trim(name or ""):gsub("[/\\%s]", "_")
  if name == "" then
    return
  end
  vim.fn.mkdir(dir, "p")
  current = name
  vim.cmd("mksession! " .. vim.fn.fnameescape(session_file(name)))
  vim.notify("セッションを保存: " .. name, vim.log.levels.INFO, { title = "session" })
end

local function load_session(name)
  current = name
  vim.cmd("source " .. vim.fn.fnameescape(session_file(name)))
  vim.notify("セッションを読み込み: " .. name, vim.log.levels.INFO, { title = "session" })
end

-- セッション一覧から選んで読み込む
function M.list()
  local names = list_sessions()
  if #names == 0 then
    vim.notify("保存済みセッションがありません (<leader>sn で作成)", vim.log.levels.INFO, { title = "session" })
    return
  end
  vim.ui.select(names, { prompt = "セッションを読み込む: " }, function(choice)
    if choice then
      load_session(choice)
    end
  end)
end

-- 新しい名前で保存
function M.new()
  vim.ui.input({ prompt = "新しいセッション名: " }, function(name)
    save_as(name)
  end)
end

-- 現在のセッションを上書き(未選択なら名前を聞く)
function M.update()
  if current then
    save_as(current)
  else
    vim.ui.input({ prompt = "保存先のセッション名: " }, function(name)
      save_as(name)
    end)
  end
end

-- セッションを選んで削除
function M.delete()
  local names = list_sessions()
  if #names == 0 then
    vim.notify("削除するセッションがありません", vim.log.levels.INFO, { title = "session" })
    return
  end
  vim.ui.select(names, { prompt = "削除するセッション: " }, function(choice)
    if not choice then
      return
    end
    vim.fn.delete(session_file(choice))
    if current == choice then
      current = nil
    end
    vim.notify("セッションを削除: " .. choice, vim.log.levels.INFO, { title = "session" })
  end)
end

function M.setup()
  vim.keymap.set("n", "<leader>sl", M.list, { silent = true, desc = "セッション一覧を読み込み" })
  vim.keymap.set("n", "<leader>sn", M.new, { silent = true, desc = "新規セッションとして保存" })
  vim.keymap.set("n", "<leader>su", M.update, { silent = true, desc = "現在のセッションを更新" })
  vim.keymap.set("n", "<leader>sd", M.delete, { silent = true, desc = "セッションを削除" })
end

return M
