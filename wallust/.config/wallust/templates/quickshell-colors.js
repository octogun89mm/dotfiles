.pragma library

function hexToRgb(hex) {
  var clean = String(hex).replace("#", "")
  if (clean.length !== 6) return { r: 0, g: 0, b: 0 }
  return {
    r: parseInt(clean.slice(0, 2), 16),
    g: parseInt(clean.slice(2, 4), 16),
    b: parseInt(clean.slice(4, 6), 16)
  }
}

function luminance(hex) {
  var c = hexToRgb(hex)
  return (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) / 255
}

function distance(a, b) {
  var ca = hexToRgb(a)
  var cb = hexToRgb(b)
  return Math.abs(ca.r - cb.r) + Math.abs(ca.g - cb.g) + Math.abs(ca.b - cb.b)
}

var base00 = "{{background}}"
var base01 = "{{color0}}"
var base02 = "{{color8}}"
var base03 = "{{color8}}"
var base04 = "{{color8}}"
var base05 = "{{foreground}}"
var base06 = "{{color15}}"
var base07 = "{{foreground}}"
var base08 = "{{color1}}"
var base09 = "{{color9}}"
var base0A = "{{color3}}"
var base0B = "{{color2}}"
var base0C = "{{color6}}"
var base0D = "{{color4}}"
var base0E = "{{color5}}"
var base0F = "{{color13}}"

var filteredSurfaceDark = "{{background | lighten(0.10)}}"
var filteredSurfaceLight = "{{background | darken(0.07)}}"
var filteredBorderDark = "{{background | lighten(0.28)}}"
var filteredBorderLight = "{{background | darken(0.18)}}"
var filteredTextMutedDark = "{{foreground | darken(0.24)}}"
var filteredTextMutedLight = "{{foreground | lighten(0.24)}}"
var filteredTextDimDark = "{{foreground | darken(0.42)}}"
var filteredTextDimLight = "{{foreground | lighten(0.42)}}"
var filteredAccentAlt = "{{color4 | complementary | saturate(0.16)}}"

var background = base00
var foreground = base05
var accent = base0D
var bgIsLight = luminance(base00) > 0.5
var filteredSurface = bgIsLight ? filteredSurfaceLight : filteredSurfaceDark
var filteredBorder = bgIsLight ? filteredBorderLight : filteredBorderDark
var filteredTextMuted = bgIsLight ? filteredTextMutedLight : filteredTextMutedDark
var filteredTextDim = bgIsLight ? filteredTextDimLight : filteredTextDimDark
var safeSurface = distance(base01, base00) < 55 ? filteredSurface : base01
var safeBorder = distance(base02, safeSurface) < 90 ? filteredBorder : base02
var safeTextMuted = distance(base04, base00) < 130 ? filteredTextMuted : base04
var safeTextDim = distance(base03, base00) < 130 ? filteredTextDim : base03
var safeAccentAlt = distance(base0E, base0D) < 90 ? filteredAccentAlt : base0E

var surface = safeSurface
var muted = safeTextDim

// Names consumed by Theme.qml
var bg = base00
var surfaceElevated = safeSurface
var border = safeBorder
var borderActive = base0D
var text = base05
var textMuted = safeTextMuted
var textDim = safeTextDim
var accentPrimary = base0D
var accentAlt = safeAccentAlt
var critical = base08
var success = base0B
var warning = base0A
var info = base0C

var color0 = "{{color0}}"
var color1 = "{{color1}}"
var color2 = "{{color2}}"
var color3 = "{{color3}}"
var color4 = "{{color4}}"
var color5 = "{{color5}}"
var color6 = "{{color6}}"
var color7 = "{{color7}}"
var color8 = "{{color8}}"
var color9 = "{{color9}}"
var color10 = "{{color10}}"
var color11 = "{{color11}}"
var color12 = "{{color12}}"
var color13 = "{{color13}}"
var color14 = "{{color14}}"
var color15 = "{{color15}}"
