-- clone 後の初回 nvim 起動時に lazygit を ~/.local/bin へ自動導入する。
-- システム領域には一切触れず、各ディストリ共通で動く静的バイナリを利用する。
--
-- ただし配布バイナリは glibc リンクのため Termux (bionic) や musl (Alpine) では
-- 実行できない。env.can_run_prebuilt() が true の環境 (glibc Linux x64/arm64,
-- macOS) でのみダウンロードし、それ以外では何もしない。
-- 未導入環境でキーを押した場合は、その環境に合った導入方法を通知する
-- (lua/plugins/snacks/init.lua, lua/plugins/lazygit.nvim.lua 側で処理)。

local env = require("config.env")
local uv = vim.uv or vim.loop

local VERSION = "0.65.0"
local bin_dir = vim.fn.expand("~/.local/bin")
local bin = bin_dir .. "/lazygit"

-- nvim 内の PATH に ~/.local/bin を優先的に追加(システムの PATH は変更しない)
vim.env.PATH = bin_dir .. ":" .. (vim.env.PATH or "")

local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "lazygit bootstrap" })
end

function M.ensure()
  if vim.fn.executable("lazygit") == 1 then
    return
  end
  -- 配布バイナリが動かない環境・取得手段が無い環境では何もしない
  if not env.can_run_prebuilt() or not env.arch then
    return
  end
  if not (env.has("curl") and env.has("tar")) then
    return
  end
  if type(vim.system) ~= "function" then
    return
  end

  local os_label = env.sysname == "linux" and "Linux" or "Darwin"
  local url = ("https://github.com/jesseduffield/lazygit/releases/download/v%s/lazygit_%s_%s_%s.tar.gz")
    :format(VERSION, VERSION, os_label, env.arch)
  local tmp = vim.fn.tempname()
  local tmpdir = vim.fn.fnamemodify(tmp, ":h")

  vim.system({ "curl", "-fL", "--retry", "2", "-o", tmp, url }, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        notify("ダウンロードに失敗しました(lazygit は手動で導入してください)\n" .. (res.stderr or ""), vim.log.levels.WARN)
        vim.fn.delete(tmp)
        return
      end
      vim.system({ "tar", "-xzf", tmp, "-C", tmpdir }, {}, function(r)
        vim.schedule(function()
          vim.fn.delete(tmp)
          local extracted = tmpdir .. "/lazygit"
          if r.code ~= 0 or vim.fn.filereadable(extracted) == 0 then
            notify("展開に失敗しました", vim.log.levels.WARN)
            vim.fn.delete(tmpdir, "rf")
            return
          end
          vim.fn.mkdir(bin_dir, "p")
          local copied = uv.fs_copyfile(extracted, bin)
          vim.fn.delete(tmpdir, "rf")
          if not copied then
            notify("インストールに失敗しました", vim.log.levels.WARN)
            return
          end
          vim.fn.setfperm(bin, "rwxr-xr-x")

          -- 実行確認。ライブラリ非互換などはここで検出して撤去する
          vim.system({ bin, "--version" }, { text = true }, function(v)
            vim.schedule(function()
              if v.code ~= 0 then
                vim.fn.delete(bin)
                notify(
                  "取得した lazygit がこの環境では実行できませんでした。手動で導入してください\n" .. (v.stderr or ""),
                  vim.log.levels.WARN
                )
              else
                notify("lazygit v" .. VERSION .. " を導入しました: " .. bin)
              end
            end)
          end)
        end)
      end)
    end)
  end)
end

-- 起動後に非同期で導入(起動時間に影響しない)
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("UserLazygitBootstrap", { clear = true }),
  once = true,
  callback = function()
    M.ensure()
  end,
})

return M
