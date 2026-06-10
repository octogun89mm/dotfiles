import QtQuick

// Compact "↓ 1.2M ↑ 88K" network rate readout.
// Values live in fixed-width slots so the widget never resizes and
// pushes its neighbours around as rates fluctuate.
Item {
  id: root

  implicitHeight: Theme.barHeight
  implicitWidth: row.implicitWidth

  TextMetrics {
    id: valueMetrics
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontMd
    text: "888.8M"
  }

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.padSm

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "N"
      color: Theme.text
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontMd
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "↓"
      color: Theme.textMuted
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontMd
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      width: valueMetrics.width
      horizontalAlignment: Text.AlignRight
      text: NetSpeedState.format(NetSpeedState.downBps)
      color: Theme.text
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontMd
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "↑"
      color: Theme.textMuted
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontMd
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      width: valueMetrics.width
      horizontalAlignment: Text.AlignRight
      text: NetSpeedState.format(NetSpeedState.upBps)
      color: Theme.text
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontMd
    }
  }
}
