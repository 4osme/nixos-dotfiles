return {
  "lewis6991/gitsigns.nvim",
  -- VSCode の Source Control 相当（行単位の変更表示・hunk操作）
  -- git 本体が無い環境ではエラー通知を避けるため読み込まない
  enabled = vim.fn.executable("git") == 1,
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~" },
      untracked = { text = "▎" },
    },
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns
      local function map(mode, l, r, desc)
        vim.keymap.set(mode, l, r, { buffer = bufnr, silent = true, desc = desc })
      end
      map("n", "]h", gs.next_hunk, "次の変更(hunk)へ")
      map("n", "[h", gs.prev_hunk, "前の変更(hunk)へ")
      map({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>", "hunkをステージ")
      map({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>", "hunkを元に戻す")
      map("n", "<leader>hS", gs.stage_buffer, "ファイル全体をステージ")
      map("n", "<leader>hu", gs.undo_stage_hunk, "ステージを取り消し")
      map("n", "<leader>hp", gs.preview_hunk, "hunkをプレビュー")
      map("n", "<leader>hb", gs.blame_line, "blameを表示")
      map("n", "<leader>hd", gs.diffthis, "前回とのdiffを表示")
    end,
  },
}
