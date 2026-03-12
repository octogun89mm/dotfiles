import QtQuick
import "wallust.js" as Wallust

Rectangle {
  id: root

  color: "transparent"
  border.width: 2
  border.color: Wallust.base03
  implicitWidth: indicator.implicitWidth + 10
  implicitHeight: 24

  Text {
    id: indicator
    anchors.centerIn: parent
    text: VpnState.icon
    color: VpnState.connected ? Wallust.base0D : Wallust.base03
    font.family: "Symbols Nerd Font Mono"
    font.pixelSize: 14
  }

  MouseArea {
    anchors.fill: parent
    onClicked: VpnState.toggle()
  }
}
