vim.o.termguicolors = true
local mode_file = vim.fn.expand("~/.cache/wallust-current-mode")
local mode = "dark"
if vim.fn.filereadable(mode_file) == 1 then
  mode = vim.trim(table.concat(vim.fn.readfile(mode_file), "\n"))
end
vim.o.background = mode == "light" and "light" or "dark"
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.g.colors_name = "wallust"

local palette = {
  background = "{{background}}",
  foreground = "{{foreground}}",
  cursor     = "{{foreground}}",
  cursorline = "{{color0}}",
  mode       = mode,
  colors = {
    color0  = "{{color0}}",
    color1  = "{{color1}}",
    color2  = "{{color2}}",
    color3  = "{{color3}}",
    color4  = "{{color4}}",
    color5  = "{{color5}}",
    color6  = "{{color6}}",
    color7  = "{{color7}}",
    color8  = "{{color8}}",
    color9  = "{{color9}}",
    color10 = "{{color10}}",
    color11 = "{{color11}}",
    color12 = "{{color12}}",
    color13 = "{{color13}}",
    color14 = "{{color14}}",
    color15 = "{{color15}}",
  },
}

local function hl(group, opts)
  -- opts: { fg = "#rrggbb", bg = "#rrggbb", bold = true, italic = true, underline = true }
  vim.api.nvim_set_hl(0, group, opts)
end

local C = palette.colors
local bg = palette.background
local fg = palette.foreground
local cursor = palette.cursor
local cursorline = palette.cursorline

-- Core UI
hl("Normal",      { fg = fg, bg = bg })
hl("Cursor",      { fg = cursor, bg = C.color5 })
hl("Visual",      { bg = C.color8 })
hl("CursorLine",  { bg = cursorline })
hl("LineNr",      { fg = C.color8 })
hl("CursorLineNr",{ fg = C.color5, bg = cursorline, bold = true })
hl("StatusLine",  { fg = fg, bg = C.color0 })
hl("StatusLineNC",{ fg = C.color8, bg = C.color0 })
hl("TabLineSel",  { fg = C.color15, bg = C.color5 })
hl("TabLine",     { fg = fg, bg = C.color0 })
hl("Whitespace",   { fg = C.color8 })

-- Text / syntax
hl("Comment",     { fg = C.color3, italic = true })
hl("Constant",    { fg = C.color5 })
hl("Identifier",  { fg = C.color4 })
hl("Statement",   { fg = C.color1 })
hl("PreProc",     { fg = C.color2 })
hl("Type",        { fg = C.color6 })
hl("Special",     { fg = C.color9 })
hl("Underlined",  { fg = C.color12 })
hl("Todo",        { fg = C.color11, bg = C.color8 })

-- Floating windows and popups
hl("Pmenu",       { fg = fg, bg = C.color0 })
hl("PmenuSel",    { fg = C.color15, bg = C.color5 })
hl("FloatBorder", { fg = C.color4, bg = C.color0 })
hl("NormalFloat", { fg = fg, bg = C.color0 })

-- End-of-buffer and non-text markers (cover both groups)
hl("EndOfBuffer", { fg = C.color8 })
hl("NonText",     { fg = bg })

-- Popup menu / completion
hl("CmpItemAbbr",      { fg = fg })
hl("CmpItemAbbrMatch", { fg = C.color4, bold = true })
hl("CmpItemKind",      { fg = C.color6 })

-- Diagnostics (optional)
hl("DiagnosticError",   { fg = C.color1 })
hl("DiagnosticWarn",    { fg = C.color3 })
hl("DiagnosticInfo",    { fg = C.color4 })
hl("DiagnosticHint",    { fg = C.color6 })

-- Groups used by Lazy.nvim UI
hl("Bold",         { bold = true })
hl("Italic",       { italic = true })
hl("Title",        { fg = C.color4, bold = true })
hl("Conceal",      { fg = C.color8 })
hl("LazyH1",      { fg = C.color15, bg = C.color4, bold = true })
hl("LazyH2",      { fg = C.color4, bold = true })
hl("LazyDimmed",  { fg = C.color8 })
hl("LazyProp",    { fg = C.color8 })

-- Terminal ANSI colors
vim.g.terminal_ansi_colors = {
  C.color0,  C.color1,  C.color2,  C.color3,
  C.color4,  C.color5,  C.color6,  C.color7,
  C.color8,  C.color9,  C.color10, C.color11,
  C.color12, C.color13, C.color14, C.color15,
}

-- Optional: set global table so other plugins can read palette
_G.wallust_palette = palette
