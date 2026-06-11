import QtQuick
import "." as Square

Item {
  id: root

  required property string screenName
  implicitHeight: Theme.barHeight
  implicitWidth: row.implicitWidth

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.padSm

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Square.NotificationState.dnd ? "DND" : "N"
      color: Square.NotificationState.dnd
        ? Theme.critical
        : Square.NotificationState.criticalCount > 0 ? Theme.critical : Theme.textMuted
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontSm
      font.bold: true
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: String(Square.NotificationState.unreadCount)
      color: Square.NotificationState.unreadCount > 0 ? Theme.text : Theme.textDim
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontMd
      font.bold: true
    }
  }

  MouseArea {
    anchors.fill: parent
    anchors.margins: -Theme.padSm
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => {
      if (mouse.button === Qt.RightButton) {
        Square.NotificationState.toggleDnd()
      } else {
        Square.NotificationState.toggleCenter(root.screenName)
      }
    }
  }
}
