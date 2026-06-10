pragma Singleton

import QtQuick
import "wallust.js" as Wallust

QtObject {
  id: theme

  // Colors — semantic (from wallust)
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

  // Typography
  readonly property string fontFamily: "Maple Mono NF"
  readonly property string iconFamily: "Symbols Nerd Font Mono"
  readonly property int fontSm: 10
  readonly property int fontMd: 11
  readonly property int fontLg: 13

  // Spacing
  readonly property int padXs: 2
  readonly property int padSm: 4
  readonly property int padMd: 8
  readonly property int padLg: 12

  // Brutalist: zero radius, everywhere.
  readonly property int radius: 0

  // Strokes
  readonly property int hairline: 1
  readonly property int stripe: 2

  // Bar geometry
  readonly property int barHeight: 30
  readonly property int wsCellSize: 30

  // Animation — keep snappy, near-instant
  readonly property int animFast: 80
}
