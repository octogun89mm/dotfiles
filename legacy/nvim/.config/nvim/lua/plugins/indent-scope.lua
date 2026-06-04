return {
  'nvim-mini/mini.indentscope',
  config = function()
    require('mini.indentscope').setup({
      symbol = '│',
    })
    vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { link = "LineNr" })
  end
}
