import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications as Notify
import "." as Square

Scope {
  id: root

  function notificationById(notificationId) {
    return Square.NotificationState.notificationById(notificationId)
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: popupWindow
      required property var modelData

      screen: modelData
      WlrLayershell.namespace: "quickshell-square-notifications-" + (modelData ? modelData.name : "default")
      WlrLayershell.layer: WlrLayer.Overlay
      color: "transparent"
      exclusiveZone: 0
      visible: Square.NotificationState.popupQueue.count > 0
      implicitWidth: 380
      implicitHeight: popupColumn.implicitHeight + Theme.padLg * 2
      mask: Region { item: popupColumn }

      anchors {
        top: true
        right: true
      }

      margins {
        top: Theme.barHeight + Theme.padMd
        right: Theme.padMd
      }

      Column {
        id: popupColumn
        anchors.top: parent.top
        anchors.right: parent.right
        width: 360
        spacing: Theme.padSm

        Repeater {
          model: Square.NotificationState.popupQueue

          Rectangle {
            required property int notificationId
            required property int timestamp
            readonly property var notification: root.notificationById(notificationId)
            readonly property bool critical: notification && notification.urgency === Notify.NotificationUrgency.Critical

            width: popupColumn.width
            height: content.implicitHeight + Theme.padMd * 2
            color: Theme.surface
            border.width: Theme.hairline
            border.color: critical ? Theme.critical : Theme.border
            visible: notification !== null

            Rectangle {
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              width: Theme.stripe + 1
              color: critical ? Theme.critical : Theme.accent
            }

            Column {
              id: content
              anchors.left: parent.left
              anchors.right: closeButton.left
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: Theme.padLg
              anchors.rightMargin: Theme.padMd
              spacing: Theme.padXs

              Text {
                width: parent.width
                text: notification ? (notification.summary || notification.appName || "Notification") : ""
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontMd
                font.bold: true
                elide: Text.ElideRight
              }

              Text {
                width: parent.width
                visible: notification && notification.body
                text: notification ? notification.body : ""
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSm
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
              }
            }

            Text {
              id: closeButton
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: Theme.padSm
              text: "x"
              color: closeArea.containsMouse ? Theme.text : Theme.textDim
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSm
              font.bold: true

              MouseArea {
                id: closeArea
                anchors.fill: parent
                anchors.margins: -Theme.padSm
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (notification) Square.NotificationState.dismissOne(notification)
                  else Square.NotificationState.removeById(notificationId)
                }
              }
            }
          }
        }
      }
    }
  }
}
