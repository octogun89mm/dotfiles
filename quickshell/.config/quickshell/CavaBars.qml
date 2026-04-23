import QtQuick
import "wallust.js" as Wallust

Item {
  id: root

  property bool mirrored: false
  property string channel: "left"
  property int columnWidth: 2
  property int rowHeight: 2
  property int rowSpacing: 1
  property var history: []

  readonly property var channelBars: channel === "right" ? CavaState.rightBars : CavaState.leftBars
  readonly property int bandCount: channelBars.length
  readonly property int maxColumns: Math.max(1, Math.floor(implicitWidth / columnWidth))

  visible: CavaState.enabled && CavaState.available
  implicitWidth: 40
  implicitHeight: bandCount > 0 ? (bandCount * rowHeight) + ((bandCount - 1) * rowSpacing) : 0

  function trimHistory() {
    if (history.length > maxColumns) {
      history = history.slice(history.length - maxColumns)
    }
  }

  function pushFrame(levels) {
    if (!levels || !levels.length) return

    const nextHistory = history.slice()
    nextHistory.push(levels.slice())
    history = nextHistory
    trimHistory()
    spectrogram.requestPaint()
  }

  function colorForLevel(level) {
    if (level >= 0.75) return Wallust.accent
    if (level >= 0.4) return Wallust.base05
    return Wallust.base03
  }

  onMaxColumnsChanged: {
    trimHistory()
    spectrogram.requestPaint()
  }

  onVisibleChanged: {
    if (!visible) {
      history = []
      spectrogram.requestPaint()
    }
  }

  Connections {
    target: CavaState

    function onLeftBarsChanged() {
      if (root.channel === "left" && root.visible) root.pushFrame(CavaState.leftBars)
    }

    function onRightBarsChanged() {
      if (root.channel === "right" && root.visible) root.pushFrame(CavaState.rightBars)
    }
  }

  Canvas {
    id: spectrogram
    anchors.fill: parent

    onPaint: {
      const ctx = getContext("2d")
      ctx.reset()

      for (let xIndex = 0; xIndex < root.history.length; xIndex++) {
        const frame = root.history[xIndex]
        const drawX = root.mirrored
          ? xIndex * root.columnWidth
          : width - ((xIndex + 1) * root.columnWidth)

        for (let band = 0; band < frame.length; band++) {
          const level = Math.max(0, Math.min(1, frame[band] || 0))
          const drawY = height - root.rowHeight - (band * (root.rowHeight + root.rowSpacing))

          ctx.globalAlpha = 0.2 + (level * 0.8)
          ctx.fillStyle = root.colorForLevel(level)
          ctx.fillRect(drawX, drawY, root.columnWidth, root.rowHeight)
        }
      }

      ctx.globalAlpha = 1.0
    }
  }
}
