import QtQuick

Rectangle {
  id: root

  color: "transparent"
  implicitWidth: labelMetrics.width + Theme.padMd * 2
  implicitHeight: Theme.chipHeight

  Text {
    id: label
    anchors.centerIn: parent
    width: labelMetrics.width
    horizontalAlignment: Text.AlignHCenter
    text: "NET ↓" + NetworkState.formatRate(NetworkState.downMbps)
      + " ↑" + NetworkState.formatRate(NetworkState.upMbps)
      + " " + String(NetworkState.signal).padStart(3, "0") + "%"
    color: NetworkState.iface !== "" ? Theme.text : Theme.textDim
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontCaption
    font.bold: true
  }

  TextMetrics {
    id: labelMetrics
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontCaption
    font.bold: true
    text: "NET ↓000.0 ↑000.0 100%"
  }
}
