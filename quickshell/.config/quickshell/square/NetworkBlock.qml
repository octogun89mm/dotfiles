import QtQuick

// Nerd font icon + interface name.
Item {
  id: root

  implicitHeight: Theme.barHeight
  implicitWidth: row.implicitWidth

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.padSm

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: NetworkState.icon
      color: NetworkState.connected ? Theme.text : Theme.textDim
      font.family: Theme.iconFamily
      font.pixelSize: Theme.fontLg
    }

    Text {
      visible: NetworkState.connected
      anchors.verticalCenter: parent.verticalCenter
      text: NetworkState.iface
      color: Theme.textMuted
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontSm
    }
  }
}
