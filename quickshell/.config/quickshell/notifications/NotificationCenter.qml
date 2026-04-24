import QtQuick
import Quickshell
import "." as Notif
import ".." as Root

Scope {
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: centerWindow
      required property var modelData

      screen: modelData
      color: "transparent"
      exclusiveZone: 0
      readonly property bool activeScreen: Notif.NotificationServer.centerScreenName === modelData.name
      visible: (Notif.NotificationServer.centerVisible && activeScreen) || slideAnim.running

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      MouseArea {
        anchors.fill: parent
        visible: Notif.NotificationServer.centerVisible && centerWindow.activeScreen
        onClicked: {
          Notif.NotificationServer.centerVisible = false
          Notif.NotificationServer.centerScreenName = ""
        }
      }

      Rectangle {
        id: panel
        readonly property int minPanelHeight: 260
        readonly property int maxPanelHeight: Math.max(minPanelHeight, modelData.height - 40)
        readonly property int desiredPanelHeight: headerRow.implicitHeight + 36
          + (historyList.visible ? historyList.contentHeight : emptyState.implicitHeight)

        width: 420
        height: Math.min(maxPanelHeight, Math.max(minPanelHeight, desiredPanelHeight))
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 46
        color: Root.Theme.surface
        border.width: Root.Theme.hairline
        border.color: Root.Theme.border

        transform: Translate {
          y: Notif.NotificationServer.centerVisible && centerWindow.activeScreen ? 0 : -(panel.height + 12)

          Behavior on y {
            NumberAnimation {
              id: slideAnim
              duration: 200
              easing.type: Easing.OutQuad
            }
          }
        }

        Column {
          id: content
          anchors.fill: parent
          anchors.margins: 12
          spacing: 12

          Item {
            id: headerRow
            width: parent.width
            height: 24

            Text {
              id: titleLabel
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: "NOTIFICATIONS"
              color: Root.Theme.textMuted
              font.family: "Iosevka"
              font.pixelSize: 10
              font.bold: true
            }

            Rectangle {
              id: unreadCountBadge
              anchors.left: titleLabel.right
              anchors.leftMargin: 8
              anchors.verticalCenter: parent.verticalCenter
              width: Math.max(24, unreadLabel.implicitWidth + 10)
              height: 20
              color: Notif.NotificationServer.unreadCount > 0 ? Root.Theme.accent : "transparent"
              border.width: Root.Theme.hairline
              border.color: Root.Theme.accent

              Text {
                id: unreadLabel
                anchors.centerIn: parent
                text: Notif.NotificationServer.unreadCount
                color: Root.Theme.text
                font.family: "Iosevka"
                font.pixelSize: 10
                font.bold: true
              }
            }

            Rectangle {
              anchors.left: unreadCountBadge.right
              anchors.leftMargin: 8
              anchors.verticalCenter: parent.verticalCenter
              id: dndButton
              width: 28
              height: 24
              color: "transparent"
              border.width: Root.Theme.hairline
              border.color: Notif.NotificationServer.dnd ? Root.Theme.critical : Root.Theme.border

              Text {
                anchors.centerIn: parent
                text: Notif.NotificationServer.dnd ? "󰂛" : "󰂚"
                color: Notif.NotificationServer.dnd ? Root.Theme.critical : Root.Theme.text
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 14
              }

              MouseArea {
                anchors.fill: parent
                onClicked: Notif.NotificationServer.toggleDnd()
              }
            }

            Rectangle {
              id: clearAllButton
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              width: clearAllLabel.implicitWidth + 14
              height: 24
              color: "transparent"
              border.width: Root.Theme.hairline
              border.color: Root.Theme.border

              Text {
                id: clearAllLabel
                anchors.centerIn: parent
                text: "CLEAR ALL"
                color: Root.Theme.text
                font.family: "Iosevka"
                font.pixelSize: 10
                font.bold: true
              }

              MouseArea {
                anchors.fill: parent
                onClicked: Notif.NotificationServer.clearAll()
              }
            }
          }

          Item {
            width: parent.width
            height: parent.height - y

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

            MouseArea {
              id: historyHover
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.NoButton
              visible: historyList.visible
            }

            Column {
              id: emptyState
              anchors.centerIn: parent
              spacing: 8
              visible: !historyList.visible

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰂚"
                color: Root.Theme.textDim
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 24
              }

              Text {
                text: "NO NOTIFICATIONS"
                color: Root.Theme.textDim
                font.family: "Iosevka"
                font.pixelSize: 11
                font.bold: true
              }
            }
          }
        }

      }
    }
  }
}
