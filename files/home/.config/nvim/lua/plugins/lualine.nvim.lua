return {
  'nvim-lualine/lualine.nvim',
  -- 起動時に読み込まず、描画準備が整った頃に遅延ロードする
  event = "VeryLazy",
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  opts = {
    options = {
      -- 画面最下部に1本化。横の窓境が WinSeparator(白線)になる
      globalstatus = true,
    },
  },
}
