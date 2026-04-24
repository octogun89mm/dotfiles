import QtQuick

Item {
  id: root

  property string label: ""
  property string value: "--"
  property var history: []
  property color accentColor: Theme.accent
  property real maxValue: 100
  property bool showGraph: true
  property int graphWidth: 28

  implicitHeight: Theme.chipHeight
  implicitWidth: row.implicitWidth + Theme.padMd * 2

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: Theme.padMd
    spacing: Theme.padSm

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.label
      color: Theme.textMuted
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontCaption
      font.bold: true
      font.letterSpacing: 0.5
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.value
      color: Theme.text
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontSmall
    }

    Canvas {
      id: spark
      visible: root.showGraph && root.history.length >= 2
      anchors.verticalCenter: parent.verticalCenter
      width: root.graphWidth
      height: 10

      onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const vals = root.history
        if (!vals || vals.length < 2) return
        const max = root.maxValue > 0 ? root.maxValue : 100
        const step = width / (vals.length - 1)

        // Fill under curve (tinted)
        ctx.beginPath()
        ctx.moveTo(0, height)
        for (let i = 0; i < vals.length; i++) {
          const n = Math.max(0, Math.min(1, vals[i] / max))
          ctx.lineTo(i * step, height - (n * height))
        }
        ctx.lineTo((vals.length - 1) * step, height)
        ctx.closePath()
        ctx.fillStyle = Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.15)
        ctx.fill()

        // Stroke
        ctx.beginPath()
        for (let j = 0; j < vals.length; j++) {
          const n = Math.max(0, Math.min(1, vals[j] / max))
          const y = height - (n * height)
          if (j === 0) ctx.moveTo(0, y)
          else ctx.lineTo(j * step, y)
        }
        ctx.strokeStyle = root.accentColor
        ctx.lineWidth = 1
        ctx.stroke()
      }
    }
  }

  onHistoryChanged: spark.requestPaint()
  onWidthChanged: spark.requestPaint()
}
