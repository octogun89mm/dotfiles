-- All the basic settings
require("settings")
-- Lazy plugins manager configuration and the list of all the plugins
require("config.lazy")
-- Import all mappings
require('mappings')
-- Theme
vim.cmd.colorscheme('wallust')
-- Neovim diagnostic config
vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = true,
})

-- 1. Enable list mode
vim.opt.list = true

-- 2. Configure how whitespace looks
vim.opt.listchars = {
  space = '·',      -- Character for space
  tab = '» ',       -- Character for tab (usually two chars: start and fill)
  trail = '·',      -- Character for trailing spaces
  extends = '›',    -- Character for text extending beyond right window edge
  precedes = '‹',   -- Character for text extending beyond left window edge
  nbsp = '␣',       -- Character for non-breaking space
}
