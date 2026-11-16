return {
  "akinsho/bufferline.nvim",
  -- VSCode 風の上部タブ（開いているバッファ = タブ）
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      mode = "buffers",
      always_show_bufferline = true,
      diagnostics = "nvim_lsp",
      offsets = {
        {
          filetype = "snacks_picker_list",
          text = "Explorer",
          text_align = "left",
          highlight = "Directory",
        },
      },
    },
  },
  keys = {
    { "[b", "<cmd>BufferLineCyclePrev<cr>", silent = true, desc = "前のタブ" },
    { "]b", "<cmd>BufferLineCycleNext<cr>", silent = true, desc = "次のタブ" },
    { "<leader>bd", "<cmd>BufferLinePickClose<cr>", silent = true, desc = "タブを選んで閉じる" },
  },
}
