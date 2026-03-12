import QtQuick
import ".." as Root

ActionCard {
  id: root

  property bool active: false

  title: "IDLE"
  icon: Root.IdleState.active ? "󰈈" : "󰈉"
  value: Root.IdleState.statusText
  highlighted: Root.IdleState.active

  onClicked: Root.IdleState.toggle()
}
