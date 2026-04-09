import QtQuick
import "../notifications" as Notif
import "../wallust.js" as Wallust

Rectangle {
  id: root

  property bool active: false
  property int maxVisibleItems: 4
  property real maxListHeight: 320
  property real minListHeight: 96
  readonly property int rowHeightEstimate: 116
  readonly property int count: Notif.NotificationServer.history.count
  readonly property real listHeight: Math.min(
    maxListHeight,
    Math.min(historyList.contentHeight, maxVisibleItems * rowHeightEstimate)
  )

  color: Wallust.base03
  border.width: 2
  border.color: Wallust.base01
  implicitHeight: content.implicitHeight + 24

  Column {
    id: content
    anchors.fill: parent
    anchors.margins: 12
    spacing: 10

    Item {
      id: headerRow
      width: parent.width
      height: 24

      Text {
        id: titleLabel
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: "NOTIFICATIONS"
        color: Wallust.base04
        font.family: "Roboto Mono"
        font.pixelSize: 10
        font.bold: true
      }

      Rectangle {
        anchors.left: titleLabel.right
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(24, countLabel.implicitWidth + 10)
        height: 20
        color: "transparent"
        border.width: 2
        border.color: Wallust.accent

        Text {
          id: countLabel
          anchors.centerIn: parent
          text: root.count
          color: Wallust.base05
          font.family: "Roboto Mono"
          font.pixelSize: 10
          font.bold: true
        }
      }

      Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: clearLabel.implicitWidth + 14
        height: 24
        color: "transparent"
        border.width: 2
        border.color: root.count > 0 ? Wallust.base01 : Wallust.base02

        Text {
          id: clearLabel
          anchors.centerIn: parent
          text: "CLEAR ALL"
          color: root.count > 0 ? Wallust.base05 : Wallust.base03
          font.family: "Roboto Mono"
          font.pixelSize: 10
          font.bold: true
        }

        MouseArea {
          anchors.fill: parent
          enabled: root.count > 0
          onClicked: Notif.NotificationServer.clearAll()
        }
      }
    }

    Item {
      width: parent.width
      height: root.count > 0 ? Math.max(root.minListHeight, root.listHeight) : emptyState.implicitHeight + 12

      ListView {
        id: historyList
        anchors.fill: parent
        clip: true
        spacing: 8
        model: Notif.NotificationServer.history
        visible: count > 0

        delegate: Notif.NotificationItem {
          required property int notificationId
          required property int timestamp

          width: historyList.width
          compact: true
          notification: Notif.NotificationServer.notificationById(notificationId)
          createdAt: timestamp
          visible: notification !== null
        }
      }

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 18
        visible: historyList.visible && historyList.contentHeight > parent.height
        gradient: Gradient {
          GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0) }
          GradientStop { position: 1.0; color: Wallust.base03 }
        }
      }

      Column {
        id: emptyState
        anchors.centerIn: parent
        spacing: 8
        visible: !historyList.visible

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "󰂚"
          color: Wallust.base04
          font.family: "Symbols Nerd Font Mono"
          font.pixelSize: 24
        }

        Text {
          text: "NO NOTIFICATIONS"
          color: Wallust.base04
          font.family: "Roboto Mono"
          font.pixelSize: 11
          font.bold: true
        }
      }
    }
  }
}
