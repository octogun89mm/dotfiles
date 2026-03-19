import QtQuick
import "../wallust.js" as Wallust

Item {
  id: root

  property var values: []
  property color graphColor: Wallust.accent
  property string label: ""
  property real maxValue: 100
  property real minValue: 0

  Text {
    id: labelText
    width: root.label !== "" ? 28 : 0
    visible: root.label !== ""
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    text: root.label
    color: Wallust.base04
    font.family: "Roboto Mono"
    font.pixelSize: 8
    font.bold: true
  }

  Canvas {
    id: canvas
    anchors.left: labelText.visible ? labelText.right : parent.left
    anchors.leftMargin: labelText.visible ? 4 : 0
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom

    onPaint: {
      var ctx = getContext("2d")
      var w = width
      var h = height
      ctx.clearRect(0, 0, w, h)

      var vals = root.values
      if (!vals || vals.length < 2 || w <= 0 || h <= 0) return

      var range = root.maxValue - root.minValue
      if (range <= 0) range = 1

      var pad = 1
      var drawH = h - pad * 2
      var step = w / (vals.length - 1)

      ctx.beginPath()
      ctx.moveTo(0, h)
      for (var i = 0; i < vals.length; i++) {
        var n = Math.max(0, Math.min(1, (vals[i] - root.minValue) / range))
        ctx.lineTo(i * step, pad + drawH - n * drawH)
      }
      ctx.lineTo((vals.length - 1) * step, h)
      ctx.closePath()
      ctx.fillStyle = Qt.rgba(root.graphColor.r, root.graphColor.g, root.graphColor.b, 0.15)
      ctx.fill()

      ctx.beginPath()
      for (var j = 0; j < vals.length; j++) {
        var m = Math.max(0, Math.min(1, (vals[j] - root.minValue) / range))
        var y = pad + drawH - m * drawH
        if (j === 0) ctx.moveTo(0, y)
        else ctx.lineTo(j * step, y)
      }
      ctx.strokeStyle = root.graphColor
      ctx.lineWidth = 1
      ctx.stroke()
    }
  }

  onValuesChanged: canvas.requestPaint()
  onWidthChanged: canvas.requestPaint()
  onHeightChanged: canvas.requestPaint()
}
