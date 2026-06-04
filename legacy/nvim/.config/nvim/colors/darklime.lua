local ok, cfg = pcall(require, 'my-theme.config')
local config = ok and cfg or { transparent = false }

local colorscheme = {
  standardWhite = '#FFFFFF',
  standardBlack = '#1E1E1E',
  editorBackground = config.transparent and 'none' or '#1E1E1E',
  sidebarBackground = '#262626',
  popupBackground = '#303030',
  floatingWindowBackground = '#4A4A4A',
  menuOptionBackground = '#262626',
  mainText = '#F2F2F2',
  emphasisText = '#FFFFFF',
  commandText = '#E6E6E6',
  inactiveText = '#4A4A4A',
  disabledText = '#B6B6B6',
  lineNumberText = '#7BD6FF',
  selectedText = '#FFFFFF',
  inactiveSelectionText = '#FF99CC',
  windowBorder = '#1E1E1E',
  focusedBorder = '#DFFF00',
  emphasizedBorder = '#A792FF',
  syntaxError = '#FF6E8A',
  syntaxFunction = '#7BD6FF',
  warningText = '#FFB54A',
  syntaxKeyword = '#A792FF',
  linkText = '#FF80F0',
  stringText = '#FFB54A',
  warningEmphasis = '#DFFF00',
  successText = '#4DFFCA',
  errorText = '#FF6E8A',
  specialKeyword = '#D066FF',
  commentText = '#B6B6B6',
  syntaxOperator = '#E6E6E6',
  foregroundEmphasis = '#FFFFFF',
  terminalGray = '#303030',
}

vim.g.colors_name = 'darklime'
vim.o.background = 'dark'

local hl = vim.api.nvim_set_hl

hl(0, 'Normal', { fg = colorscheme.mainText, bg = colorscheme.editorBackground })
hl(0, 'NormalFloat', { fg = colorscheme.mainText, bg = colorscheme.floatingWindowBackground })
hl(0, 'FloatBorder', { fg = colorscheme.windowBorder, bg = colorscheme.floatingWindowBackground })
hl(0, 'Pmenu', { fg = colorscheme.mainText, bg = colorscheme.popupBackground })
hl(0, 'PmenuSel', { fg = colorscheme.selectedText, bg = colorscheme.menuOptionBackground })
hl(0, 'CursorLine', { bg = colorscheme.popupBackground })
hl(0, 'CursorLineNr', { fg = colorscheme.focusedBorder, bold = true })
hl(0, 'LineNr', { fg = colorscheme.lineNumberText })
hl(0, 'Comment', { fg = colorscheme.commentText, italic = true })
hl(0, 'Function', { fg = colorscheme.syntaxFunction })
hl(0, 'Identifier', { fg = colorscheme.syntaxFunction })
hl(0, 'Keyword', { fg = colorscheme.syntaxKeyword, bold = true })
hl(0, 'Statement', { fg = colorscheme.syntaxKeyword })
hl(0, 'Operator', { fg = colorscheme.syntaxOperator })
hl(0, 'Constant', { fg = colorscheme.stringText })
hl(0, 'String', { fg = colorscheme.stringText })
hl(0, 'Error', { fg = colorscheme.errorText })
hl(0, 'ErrorMsg', { fg = colorscheme.errorText, bg = colorscheme.editorBackground })
hl(0, 'WarningMsg', { fg = colorscheme.warningText })
hl(0, 'Todo', { fg = colorscheme.warningEmphasis, bold = true })
hl(0, 'Special', { fg = colorscheme.specialKeyword })
hl(0, 'Underlined', { fg = colorscheme.linkText, underline = true })
hl(0, 'Visual', { bg = colorscheme.inactiveSelectionText })
hl(0, 'Search', { fg = colorscheme.foregroundEmphasis, bg = colorscheme.warningEmphasis })
hl(0, 'IncSearch', { fg = colorscheme.foregroundEmphasis, bg = colorscheme.warningText })
hl(0, 'StatusLine', { fg = colorscheme.commandText, bg = colorscheme.sidebarBackground })
hl(0, 'StatusLineNC', { fg = colorscheme.disabledText, bg = colorscheme.sidebarBackground })
hl(0, 'TabLine', { fg = colorscheme.disabledText, bg = colorscheme.sidebarBackground })
hl(0, 'TabLineSel', { fg = colorscheme.active and colorscheme.standardBlack or colorscheme.standardBlack, bg = colorscheme.focusedBorder })
hl(0, 'Title', { fg = colorscheme.focusedBorder, bold = true })
hl(0, 'Cursor', { fg = colorscheme.cursor and colorscheme.standardBlack or colorscheme.standardBlack, bg = colorscheme.standardWhite })
hl(0, 'VisualNOS', { fg = colorscheme.mainText, bg = colorscheme.inactiveSelectionText })
hl(0, 'DiffAdd', { fg = colorscheme.successText })
hl(0, 'DiffChange', { fg = colorscheme.warningEmphasis })
hl(0, 'DiffDelete', { fg = colorscheme.syntaxError })
hl(0, 'DiffText', { fg = colorscheme.linkText })
hl(0, 'Directory', { fg = colorscheme.linkText })
hl(0, 'Boolean', { fg = colorscheme.successText })
hl(0, 'Type', { fg = colorscheme.syntaxKeyword })
hl(0, 'PreProc', { fg = colorscheme.specialKeyword })
hl(0, 'CursorColumn', { bg = colorscheme.popupBackground })

