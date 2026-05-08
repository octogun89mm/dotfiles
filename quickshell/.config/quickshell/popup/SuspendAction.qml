import QtQuick
import ".." as Root

ActionCard {
  id: root

  property bool active: false

  title: "SUSPEND"
  icon: Root.SuspendState.icon
  value: Root.SuspendState.statusText
  highlighted: !Root.SuspendState.enabled

  onClicked: Root.SuspendState.toggle()
}
