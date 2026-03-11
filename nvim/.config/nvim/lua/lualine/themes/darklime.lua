local colors = {
  bg = '#1E1E1E',
  fg = '#F2F2F2',
  sidebar = '#262626',
  popup = '#303030',
  float = '#4A4A4A',
  yellow = '#DFFF00',
  cyan = '#7BD6FF',
  green = '#4DFFCA',
  orange = '#FFB54A',
  violet = '#A792FF',
  magenta = '#D066FF',
  red = '#FF6E8A',
  pink = '#FF99CC',
  light = '#262626',
  muted = '#B6B6B6',
}

local theme = {
  normal = {
    a = { fg = colors.bg, bg = colors.yellow, gui = 'bold' },
    b = { fg = colors.fg, bg = colors.sidebar },
    c = { fg = colors.fg, bg = colors.light },
  },
  insert = {
    a = { fg = colors.bg, bg = colors.cyan, gui = 'bold' },
    b = { fg = colors.fg, bg = colors.sidebar },
    c = { fg = colors.fg, bg = colors.light },
  },
  visual = {
    a = { fg = colors.bg, bg = colors.pink, gui = 'bold' },
    b = { fg = colors.fg, bg = colors.sidebar },
    c = { fg = colors.fg, bg = colors.light },
  },
  replace = {
    a = { fg = colors.bg, bg = colors.red, gui = 'bold' },
    b = { fg = colors.fg, bg = colors.sidebar },
    c = { fg = colors.fg, bg = colors.light },
  },
  command = {
    a = { fg = colors.bg, bg = colors.violet, gui = 'bold' },
    b = { fg = colors.fg, bg = colors.sidebar },
    c = { fg = colors.fg, bg = colors.light },
  },
  inactive = {
    a = { fg = colors.muted, bg = colors.bg, gui = 'bold' },
    b = { fg = colors.muted, bg = colors.bg },
    c = { fg = colors.muted, bg = colors.light },
  },
}

return theme
