import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications as Notify
import "." as Square

Scope {
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: centerWindow
      required property var modelData
      readonly property bool activeScreen: Square.NotificationState.centerScreenName === modelData.name

      screen: modelData
      WlrLayershell.namespace: "quickshell-square-notification-center-" + (modelData ? modelData.name : "default")
      WlrLayershell.layer: WlrLayer.Overlay
      color: "transparent"
      exclusiveZone: 0
      visible: (Square.NotificationState.centerVisible && activeScreen) || slide.running

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      MouseArea {
        anchors.fill: parent
        visible: Square.NotificationState.centerVisible && centerWindow.activeScreen
        onClicked: {
          Square.NotificationState.centerVisible = false
          Square.NotificationState.centerScreenName = ""
        }
      }

      Rectangle {
        id: panel
        width: 380
        height: Math.min(modelData.height - Theme.barHeight - Theme.padLg * 2, 430)
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.barHeight + Theme.padMd
        anchors.rightMargin: Theme.padMd
        color: Theme.surface
        border.width: Theme.hairline
        border.color: Theme.border

        transform: Translate {
          y: Square.NotificationState.centerVisible && centerWindow.activeScreen ? 0 : -(panel.height + Theme.padLg)

          Behavior on y {
            NumberAnimation {
              id: slide
              duration: 160
              easing.type: Easing.OutCubic
            }
          }
        }

        Column {
          anchors.fill: parent
          anchors.margins: Theme.padMd
          spacing: Theme.padMd

          Row {
            width: parent.width
            spacing: Theme.padMd

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "NOTIFICATIONS"
              color: Theme.textMuted
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSm
              font.bold: true
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: String(Square.NotificationState.unreadCount)
              color: Square.NotificationState.criticalCount > 0 ? Theme.critical : Theme.text
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontMd
              font.bold: true
            }

            Item {
              width: 1
              height: 1
              LayoutMirroring.enabled: false
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: Square.NotificationState.dnd ? "DND ON" : "DND OFF"
              color: Square.NotificationState.dnd ? Theme.critical : Theme.textDim
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSm
              font.bold: true

              MouseArea {
                anchors.fill: parent
                anchors.margins: -Theme.padSm
                cursorShape: Qt.PointingHandCursor
                onClicked: Square.NotificationState.toggleDnd()
              }
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "CLEAR"
              color: clearArea.containsMouse ? Theme.text : Theme.textDim
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSm
              font.bold: true

              MouseArea {
                id: clearArea
                anchors.fill: parent
                anchors.margins: -Theme.padSm
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Square.NotificationState.clearAll()
              }
            }
          }

          Rectangle {
            width: parent.width
            height: Theme.hairline
            color: Theme.border
          }

          Item {
            width: parent.width
            height: parent.height - y

            ListView {
              id: list
              anchors.fill: parent
              clip: true
              spacing: Theme.padSm
              model: Square.NotificationState.history
              visible: count > 0

              delegate: Rectangle {
                required property int notificationId
                required property int timestamp
                readonly property var notification: Square.NotificationState.notificationById(notificationId)
                readonly property bool critical: Square.NotificationState.isCritical(notification)

                width: list.width
                height: itemContent.implicitHeight + Theme.padMd * 2
                color: "transparent"
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
                  id: itemContent
                  anchors.left: parent.left
                  anchors.right: dismiss.left
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
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                  }
                }

                Text {
                  id: dismiss
                  anchors.right: parent.right
                  anchors.top: parent.top
                  anchors.margins: Theme.padSm
                  text: "x"
                  color: dismissArea.containsMouse ? Theme.text : Theme.textDim
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSm
                  font.bold: true

                  MouseArea {
                    id: dismissArea
                    anchors.fill: parent
                    anchors.margins: -Theme.padSm
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Square.NotificationState.dismissOne(notification)
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  anchors.rightMargin: 28
                  cursorShape: Qt.PointingHandCursor
                  onClicked: Square.NotificationState.invokeDefault(notification)
                }
              }
            }

            Column {
              anchors.centerIn: parent
              spacing: Theme.padSm
              visible: !list.visible

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "N"
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLg
                font.bold: true
              }

              Text {
                text: "NO NOTIFICATIONS"
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSm
                font.bold: true
              }
            }
          }
        }
      }
    }
  }
}
