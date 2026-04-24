import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications as Notifications
import "." as Notif
import ".." as Root

Rectangle {
  id: root

  required property var notification
  required property int createdAt
  property bool compact: false
  property bool hovered: hoverArea.containsMouse
  readonly property bool closeVisible: compact || hovered

  readonly property bool critical: notification && notification.urgency === Notifications.NotificationUrgency.Critical
  readonly property color accentColor: {
    if (!notification) return Root.Theme.textDim
    switch (notification.urgency) {
    case Notifications.NotificationUrgency.Low:
      return Root.Theme.textDim
    case Notifications.NotificationUrgency.Critical:
      return Root.Theme.critical
    default:
      return Root.Theme.accent
    }
  }

  function relativeTime() {
    const _tick = Notif.NotificationServer.timeRevision
    const elapsedSeconds = Math.max(0, Math.floor(Date.now() / 1000) - createdAt)

    if (elapsedSeconds < 45) return "now"
    if (elapsedSeconds < 3600) return Math.floor(elapsedSeconds / 60) + "m"
    if (elapsedSeconds < 86400) return Math.floor(elapsedSeconds / 3600) + "h"
    return Math.floor(elapsedSeconds / 86400) + "d"
  }

  function actionButtons() {
    if (!notification || !notification.actions) return []

    const actions = []

    for (let i = 0; i < notification.actions.length; i++) {
      const action = notification.actions[i]
      if (action.identifier !== "default") actions.push(action)
    }

    return actions
  }

  color: critical ? Root.Theme.bg : Root.Theme.surface
  border.width: Root.Theme.hairline
  border.color: Root.Theme.border
  implicitWidth: compact ? 392 : 360
  implicitHeight: content.implicitHeight + Root.Theme.padLg * 2
  height: implicitHeight

  // Urgency stripe (left, thick)
  Rectangle {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: Root.Theme.stripeThick
    color: root.accentColor
  }

  MouseArea {
    id: hoverArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onClicked: {
      if (root.notification) {
        Notif.NotificationServer.invokeDefault(root.notification)
      }
    }
  }

  Row {
    id: content
    anchors.fill: parent
    anchors.margins: Root.Theme.padLg
    anchors.leftMargin: Root.Theme.stripeThick + Root.Theme.padLg
    anchors.rightMargin: 28
    spacing: Root.Theme.padMd

    Column {
      width: hasImage ? parent.width - 58 : parent.width
      spacing: Root.Theme.padMd

      readonly property bool hasImage: root.notification && root.notification.image

      Item {
        width: parent.width
        height: 24

        Rectangle {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          width: 24
          height: 24
          color: "transparent"

          IconImage {
            anchors.fill: parent
            source: root.notification && root.notification.appIcon ? root.notification.appIcon : ""
            asynchronous: true
          }

          Text {
            anchors.centerIn: parent
            visible: !root.notification || !root.notification.appIcon
            text: "󰂚"
            color: Root.Theme.textMuted
            font.family: Root.Theme.iconFamily
            font.pixelSize: Root.Theme.fontTitle + 2
          }
        }

        Text {
          anchors.left: parent.left
          anchors.leftMargin: 32
          anchors.right: timeLabel.left
          anchors.rightMargin: Root.Theme.padMd
          anchors.verticalCenter: parent.verticalCenter
          text: root.notification ? (root.notification.appName || root.notification.desktopEntry || "APP") : "APP"
          elide: Text.ElideRight
          color: Root.Theme.textMuted
          font.family: Root.Theme.fontFamily
          font.pixelSize: Root.Theme.fontCaption
          font.bold: true
          font.letterSpacing: 0.6
        }

        Text {
          id: timeLabel
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          text: root.relativeTime()
          color: Root.Theme.textDim
          font.family: Root.Theme.fontFamily
          font.pixelSize: Root.Theme.fontCaption
        }
      }

      Text {
        width: parent.width
        text: root.notification ? root.notification.summary : ""
        elide: Text.ElideRight
        color: Root.Theme.text
        font.family: Root.Theme.fontFamily
        font.pixelSize: root.compact ? Root.Theme.fontSmall : Root.Theme.fontBody
        font.bold: true
      }

      Text {
        width: parent.width
        visible: text !== ""
        wrapMode: Text.Wrap
        textFormat: Text.RichText
        text: root.notification ? (root.notification.body || "") : ""
        color: Root.Theme.textMuted
        font.family: Root.Theme.fontFamily
        font.pixelSize: Root.Theme.fontCaption
      }

      Row {
        visible: repeater.count > 0
        spacing: Root.Theme.padMd

        Repeater {
          id: repeater
          model: root.actionButtons()

          Rectangle {
            required property var modelData

            width: Math.max(72, actionLabel.implicitWidth + 14)
            height: 24
            color: "transparent"
            border.width: Root.Theme.hairline
            border.color: Root.Theme.border

            Text {
              id: actionLabel
              anchors.centerIn: parent
              text: modelData.text
              color: Root.Theme.text
              font.family: Root.Theme.fontFamily
              font.pixelSize: Root.Theme.fontCaption
              font.bold: true
              font.letterSpacing: 0.5
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onClicked: modelData.invoke()
              onContainsMouseChanged: parent.border.color = containsMouse ? Root.Theme.accent : Root.Theme.border
            }
          }
        }
      }
    }

    Image {
      width: 48
      height: 48
      visible: root.notification && root.notification.image
      source: root.notification ? root.notification.image : ""
      fillMode: Image.PreserveAspectFit
      asynchronous: true
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  Rectangle {
    id: closeButton
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: Root.Theme.padMd
    anchors.rightMargin: Root.Theme.padMd
    width: 18
    height: 18
    visible: root.closeVisible
    color: "transparent"
    border.width: Root.Theme.hairline
    border.color: Root.Theme.border

    Text {
      anchors.centerIn: parent
      text: "󰅖"
      color: Root.Theme.text
      font.family: Root.Theme.iconFamily
      font.pixelSize: Root.Theme.fontCaption
    }

    MouseArea {
      anchors.fill: parent
      onClicked: Notif.NotificationServer.dismissOne(root.notification)
    }
  }
}
