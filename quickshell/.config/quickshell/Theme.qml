pragma Singleton

import QtQuick
import "wallust.js" as Wallust

QtObject {
  id: theme

  // Colors — semantic
  readonly property color bg: Wallust.bg
  readonly property color surface: Wallust.surfaceElevated
  readonly property color border: Wallust.border
  readonly property color borderActive: Wallust.borderActive
  readonly property color foreground: Wallust.foreground
  readonly property color text: Wallust.text
  readonly property color textMuted: Wallust.textMuted
  readonly property color textDim: Wallust.textDim
  readonly property color accent: Wallust.accentPrimary
  readonly property color accentAlt: Wallust.accentAlt
  readonly property color critical: Wallust.critical
  readonly property color success: Wallust.success
  readonly property color warning: Wallust.warning
  readonly property color info: Wallust.info

  // Typography — 4-step scale
  readonly property string fontFamily: "Iosevka"
  readonly property string iconFamily: "Symbols Nerd Font Mono"
  readonly property int fontCaption: 10
  readonly property int fontSmall: 11
  readonly property int fontBody: 12
  readonly property int fontTitle: 14

  // Spacing — 5 rungs
  readonly property int padXs: 2
  readonly property int padSm: 4
  readonly property int padMd: 8
  readonly property int padLg: 12
  readonly property int padXl: 16

  // Bar dimensions
  readonly property int rowHeight: 18
  readonly property int barHeight: 36
  readonly property int chipHeight: 18
  readonly property int overlayChipHeight: 24

  // Strokes
  readonly property int hairline: 1
  readonly property int stripe: 2
  readonly property int stripeThick: 3
}
