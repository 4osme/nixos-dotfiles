-- 実行環境と外部ツールの検出(起動時に1回だけ評価)
--
-- 「Linux全般 + Termux」で同じ設定を使えるようにするための土台。
-- ここで検出した結果をもとに、各プラグインは
--  ・ツールがある環境では通常どおり機能を使う
--  ・無い環境では機能だけを無効化し、内蔵機能へフォールバックする
-- という判断を行う。
--
-- 方針: 追加の依存関係を「必須」にしない。無くても起動・編集は壊れない。

local M = {}

local uv = vim.uv or vim.loop

local function exec(name)
  return name ~= nil and name ~= "" and vim.fn.executable(name) == 1
end

function M.pick(...)
  for _, name in ipairs({ ... }) do
    if exec(name) then
      return name
    end
  end
  return nil
end

local uname = uv.os_uname()
M.sysname = (uname.sysname or ""):lower()
M.machine = uname.machine or ""

-- 配布バイナリのアーキテクチャ名への変換(lazygit 等)
M.arch = ({
  x86_64 = "x86_64",
  amd64 = "x86_64",
  aarch64 = "arm64",
  arm64 = "arm64",
  armv7l = "armv6",
  armv8l = "armv6",
})[M.machine]

-- Termux (Android/bionic) 判定
M.is_termux = ((vim.env.PREFIX or ""):find("com.termux", 1, true) ~= nil)
  or vim.env.TERMUX_VERSION ~= nil

-- musl libc (Alpine 等) 判定。glibc 向け配布バイナリが動かない環境
M.is_musl = vim.fn.filereadable("/etc/alpine-release") == 1
  or vim.fn.glob("/lib/ld-musl-*.so.1", false, true)[1] ~= nil

M.tools = {
  git = M.pick("git"),
  rg = M.pick("rg"),
  lazygit = M.pick("lazygit"),
  cc = M.pick("cc", "gcc", "clang"),
  curl = M.pick("curl"),
  tar = M.pick("tar"),
}

function M.has(name)
  return M.tools[name] ~= nil
end

-- glibc 向けの静的バイナリ(lazygit 等)が動く見込みの環境か。
-- Termux・musl では動かないため自動ダウンロードを禁止する。
function M.can_run_prebuilt()
  if M.is_termux or M.is_musl then
    return false
  end
  if M.sysname ~= "linux" and M.sysname ~= "darwin" then
    return false
  end
  return M.arch ~= nil
end

-- パッケージマネージャごとの導入パッケージ名
local PACKAGES = {
  rg = { pkg = "ripgrep", apk = "ripgrep", apt = "ripgrep", dnf = "ripgrep", pacman = "ripgrep", brew = "ripgrep" },
  lazygit = { pkg = "lazygit", apk = "lazygit", dnf = "lazygit", pacman = "lazygit", brew = "lazygit" },
  cc = { pkg = "clang", apk = "build-base", apt = "build-essential", dnf = "gcc", pacman = "base-devel", brew = "llvm" },
  git = { pkg = "git", apk = "git", apt = "git", dnf = "git", pacman = "git", brew = "git" },
  ["lua-language-server"] = { pkg = "lua-language-server", apk = "lua-language-server", brew = "lua-language-server" },
}

local MANAGERS = {
  { bin = "pkg", cmd = "pkg install %s" },
  { bin = "apk", cmd = "sudo apk add %s" },
  { bin = "apt", cmd = "sudo apt install %s" },
  { bin = "dnf", cmd = "sudo dnf install %s" },
  { bin = "pacman", cmd = "sudo pacman -S %s" },
  { bin = "brew", cmd = "brew install %s" },
}

-- ツールを入れるためのヒント文を環境に合わせて返す
function M.install_hint(tool)
  for _, m in ipairs(MANAGERS) do
    if exec(m.bin) then
      local names = PACKAGES[tool]
      local name = names and names[m.bin]
      if name then
        return m.cmd:format(name)
      end
    end
  end
  if tool == "lazygit" then
    return "GitHub Releases のバイナリを ~/.local/bin/lazygit に配置"
  end
  return ("パッケージマネージャで %s を導入"):format(tool)
end

-- 機能を使おうとした時に「何が足りないか」を一度だけ通知する
function M.notify_missing(tool, feature)
  vim.notify_once(
    ("%s には `%s` が必要です。%s"):format(feature, tool, M.install_hint(tool)),
    vim.log.levels.WARN,
    { title = "nvim" }
  )
end

return M
