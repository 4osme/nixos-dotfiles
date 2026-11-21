-- grep したファイル群の文字列をまとめて置換するためのプラグイン
-- ripgrep (rg) でプロジェクト全体を検索し、バッファ上で結果を編集 → <leader>rr で一括置換
--
-- rg が無い環境ではプラグイン自体を使わず、キー押下時に導入方法を通知する
-- (Neovim 内蔵の置換は :%s や grug-far 無しでも行える)
local env = require("config.env")

local function open_with_rg(opts)
  if not env.has("rg") then
    env.notify_missing("rg", "Grep & Replace")
    return
  end
  require("grug-far").open(opts)
end

return {
  'MagicDuck/grug-far.nvim',
  cmd = { 'GrugFar', 'GrugFarWithin' },
  keys = {
    {
      '<leader>rr',
      function() open_with_rg() end,
      mode = { 'n' },
      desc = 'Grep & Replace(プロジェクト全体)',
    },
    {
      '<leader>rw',
      function() open_with_rg({ prefills = { search = vim.fn.expand('<cword>') } }) end,
      mode = { 'n' },
      desc = 'Grep & Replace(カーソル下の単語)',
    },
    {
      '<leader>rf',
      function() open_with_rg({ prefills = { paths = vim.fn.expand('%') } }) end,
      mode = { 'n' },
      desc = 'Grep & Replace(現在のファイル)',
    },
    {
      '<leader>rr',
      function()
        if not env.has("rg") then
          env.notify_missing("rg", "Grep & Replace")
          return
        end
        require('grug-far').with_visual_selection({ prefills = { paths = vim.fn.expand('%') } })
      end,
      mode = { 'x' },
      desc = 'Grep & Replace(選択範囲の文字列)',
    },
  },
  opts = {
    -- 検索欄などを日本語で表示
    headerMaxWidth = 80,
    keymaps = {
      replace = { n = '<leader>rp' },       -- 置換を実行
      qflist = { n = '<leader>rq' },        -- 結果を quickfix へ
      syncLocations = { n = '<leader>rs' }, -- バッファの編集をファイルへ反映
      syncLine = { n = '<leader>rl' },
      close = { n = '<leader>rc' },
      historyOpen = { n = '<leader>rt' },
      historyAdd = { n = '<leader>ra' },
      refresh = { n = '<leader>rn' },
      openLocation = { n = '<leader>ro' },
      gotoLocation = { n = '<enter>' },
      pickHistoryEntry = { n = '<enter>' },
    },
  },
}
