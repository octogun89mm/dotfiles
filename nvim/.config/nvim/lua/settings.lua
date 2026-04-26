-- Activate numbers and relative numbers
vim.opt.number = true
vim.opt.relativenumber = true
-- Turn tabs into 2 spaces
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
-- Turn syntax on
vim.opt.syntax = "on"
-- Ignore cases when searching
vim.opt.ignorecase = true
vim.opt.smartcase = true
-- Uses term colors and expand usable colors 
vim.opt.termguicolors = true
-- Deactivate splash screen
vim.opt.shortmess:append('I')
-- Deactivate in-mode indicator in the command line since Lualine is present
vim.opt.showmode = false
-- Highlight the current line
vim.opt.cursorline = true
-- Block cursor in every mode (including insert)
vim.opt.guicursor = "n-v-c-sm-i-ci-ve:block,r-cr-o:hor20"
-- Workaround for nvimcmp
vim.opt.completeopt = { "menu", "menuone", "noinsert" }
-- Theme
vim.cmd.colorscheme('wallust')
-- Always show signcolumn with padding to avoid flicker
vim.opt.signcolumn = "yes:2"
-- Hack to keep the cursor in the middle of the screen
vim.opt.scrolloff = 999
-- Netrw settings
vim.g.netrw_liststyle = 0
vim.g.netrw_banner = 0
-- Persistent undo
vim.opt.undofile = true
-- More predictable splits
vim.opt.splitright = true
vim.opt.splitbelow = true
-- 4 spaces indent for C files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "c",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})
-- Faster update time (Refresh)
vim.opt.updatetime = 250
-- Neovim diagnostic config
vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = true,
})
-- Enable list mode
vim.opt.list = true
-- Configure how whitespace looks
vim.opt.listchars = {
  space = '·',
  tab = '» ',
  trail = '·',
  extends = '›',
  precedes = '‹',
  nbsp = '␣',
}
