import QtQuick
import "notifications" as Notif
import "wallust.js" as Wallust

Rectangle {
  id: root
  required property string screenName

  readonly property color foregroundColor: {
    if (Notif.NotificationServer.dnd) return Wallust.base03
    if (Notif.NotificationServer.centerVisible && Notif.NotificationServer.centerScreenName === screenName) return Wallust.base0D
    if (Notif.NotificationServer.criticalCount > 0) return Wallust.base08
    return Wallust.base05
  }

  color: "transparent"
  border.width: 2
  border.color: Notif.NotificationServer.centerVisible && Notif.NotificationServer.centerScreenName === screenName ? Wallust.base0D : Wallust.base03
  implicitWidth: countLabel.implicitWidth + 10
  implicitHeight: 24

  Text {
    id: countLabel
    anchors.centerIn: parent
    text: String(Notif.NotificationServer.unreadCount).padStart(2, '0')
    color: root.foregroundColor
    font.family: "Roboto Mono"
    font.pixelSize: 12
    font.bold: true
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onClicked: mouse => {
      if (mouse.button === Qt.RightButton) {
        Notif.NotificationServer.toggleDnd()
      } else {
        Notif.NotificationServer.toggleCenter(root.screenName)
      }
    }
  }
}
