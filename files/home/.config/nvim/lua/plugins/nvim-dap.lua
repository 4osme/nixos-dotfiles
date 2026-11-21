return {
  "mfussenegger/nvim-dap",
  -- デバッグ開始時のみロード（:Dap コマンド群で起動）
  -- 言語固有のアダプタ（dap-go 等）は必要に応じて dependencies に追加する
  cmd = {
    "DapToggleBreakpoint",
    "DapContinue",
    "DapDisconnect",
    "DapStepInto",
    "DapStepOver",
    "DapStepOut",
    "DapTerminate",
  },
  config = function()
    -- アダプタは各言語用プラグインで設定する
  end,
}
