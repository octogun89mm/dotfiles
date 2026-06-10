import QtQuick

// Compact "↓ 1.2M ↑ 88K" network rate readout.
Item {
  id: root

  implicitHeight: Theme.barHeight
  implicitWidth: label.implicitWidth

  Text {
    id: label
    anchors.verticalCenter: parent.verticalCenter
    textFormat: Text.StyledText
    text: "<font color='" + Theme.textMuted + "'>↓</font> "
      + NetSpeedState.format(NetSpeedState.downBps)
      + "  <font color='" + Theme.textMuted + "'>↑</font> "
      + NetSpeedState.format(NetSpeedState.upBps)
    color: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontMd
  }
}
