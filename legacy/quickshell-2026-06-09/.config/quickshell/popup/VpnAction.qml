import QtQuick
import ".." as Root

ActionCard {
  id: root

  property bool active: false

  title: "VPN"
  icon: Root.VpnState.connected ? "󰒘" : "󰒙"
  value: Root.VpnState.statusText
  highlighted: Root.VpnState.connected

  onClicked: Root.VpnState.toggle()
}
