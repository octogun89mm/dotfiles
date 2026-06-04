return {
  'mg979/vim-visual-multi',
  branch = 'master',
  event = 'VeryLazy',
  init = function()
    vim.g.VM_maps = {
      ['Goto Prev'] = '',
      ['Goto Next'] = '',
    }
  end,
}
