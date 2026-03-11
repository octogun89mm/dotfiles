return {
  'folke/zen-mode.nvim',
  config = function()
    require("zen-mode").setup({
      window = {
        width = 80,
        options = {
          number = true,
          relativenumber = true,
          signcolumn = "yes:2",
        },
      },
    })
  end
}
