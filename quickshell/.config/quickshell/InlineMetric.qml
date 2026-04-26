import QtQuick

Item {
  id: root

  property string label: ""
  property string value: "--"
  property string detail: ""
  property var history: []
  property color accentColor: Theme.accent
  property real maxValue: 100
  property bool showDetail: false
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

    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.showDetail && root.detail !== ""
      text: root.detail
      color: Theme.textDim
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontCaption
    }

    Item {
      id: sparkWrap
      visible: root.showGraph && root.history.length >= 2
      anchors.verticalCenter: parent.verticalCenter
      width: root.graphWidth + 4
      height: 12

      Rectangle {
        anchors.fill: parent
        color: Theme.surface
        radius: 0
      }

      Canvas {
        id: spark
        anchors.centerIn: parent
        width: root.graphWidth
        height: 10

        function pointY(value) {
          const max = root.maxValue > 0 ? root.maxValue : 100
          const n = Math.max(0, Math.min(1, value / max))
          return height - (n * height)
        }

        function drawCurve(ctx, vals, step) {
          ctx.moveTo(0, pointY(vals[0]))
          for (let i = 1; i < vals.length - 1; i++) {
            const x = i * step
            const y = pointY(vals[i])
            const nextX = (i + 1) * step
            const nextY = pointY(vals[i + 1])
            ctx.quadraticCurveTo(x, y, (x + nextX) / 2, (y + nextY) / 2)
          }

          const last = vals.length - 1
          ctx.lineTo(last * step, pointY(vals[last]))
        }

        onPaint: {
          const ctx = getContext("2d")
          ctx.reset()
          const vals = root.history
          if (!vals || vals.length < 2) return
          const step = width / (vals.length - 1)

          ctx.lineCap = "round"
          ctx.lineJoin = "round"

          ctx.beginPath()
          ctx.moveTo(0, Math.round(height * 0.7) + 0.5)
          ctx.lineTo(width, Math.round(height * 0.7) + 0.5)
          ctx.strokeStyle = Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
          ctx.lineWidth = 1
          ctx.stroke()

          ctx.beginPath()
          ctx.moveTo(0, height)
          drawCurve(ctx, vals, step)
          ctx.lineTo(width, height)
          ctx.closePath()
          const fill = ctx.createLinearGradient(0, 0, 0, height)
          fill.addColorStop(0, Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.24))
          fill.addColorStop(1, Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.04))
          ctx.fillStyle = fill
          ctx.fill()

          ctx.beginPath()
          drawCurve(ctx, vals, step)
          ctx.strokeStyle = Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.32)
          ctx.lineWidth = 3
          ctx.stroke()

          ctx.beginPath()
          drawCurve(ctx, vals, step)
          ctx.strokeStyle = root.accentColor
          ctx.lineWidth = 1.15
          ctx.stroke()
        }
      }
    }
  }

  onHistoryChanged: spark.requestPaint()
  onGraphWidthChanged: spark.requestPaint()
}
