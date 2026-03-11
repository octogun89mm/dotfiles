return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    require('lualine').setup({
      options = {
        globalstatus = true,
        theme = 'wallust',
        section_separators = '',
        component_separators = '',
        always_show_tabline = false
      },
      sections = {
        lualine_x = { "codecompanion", "encoding", "fileformat", "filetype" },
      }
    })
    end
}
