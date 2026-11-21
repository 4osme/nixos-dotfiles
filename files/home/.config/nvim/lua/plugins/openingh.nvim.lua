return{
  "almo7aya/openingh.nvim",
  keys = {
    { "<Leader>gr", "<Cmd>OpenInGHRepo<CR>", mode = "n", silent = true, desc = "GitHubリポジトリを開く" },
    { "<Leader>gf", "<Cmd>OpenInGHFile<CR>", mode = "n", silent = true, desc = "GitHubでファイルを開く" },
    { "<Leader>gf", "<Cmd>OpenInGHFileLines<CR>", mode = "v", silent = true, desc = "GitHubで選択行を開く" },
  }
}
