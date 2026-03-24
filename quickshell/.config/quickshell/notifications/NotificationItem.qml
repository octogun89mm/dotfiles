import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications as Notifications
import "." as Notif
import "../wallust.js" as Wallust

Rectangle {
  id: root

  required property var notification
  required property int createdAt
  property bool compact: false
  property bool hovered: hoverArea.containsMouse
  readonly property bool closeVisible: compact || hovered

  readonly property bool critical: notification && notification.urgency === Notifications.NotificationUrgency.Critical
  readonly property color accentColor: {
    if (!notification) return Wallust.base03
    switch (notification.urgency) {
    case Notifications.NotificationUrgency.Low:
      return Wallust.base03
    case Notifications.NotificationUrgency.Critical:
      return Wallust.base08
    default:
      return Wallust.accent
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

  color: critical ? Wallust.base01 : (compact ? Wallust.base03 : Wallust.base01)
  border.width: 2
  border.color: accentColor
  implicitWidth: compact ? 392 : 360
  implicitHeight: content.implicitHeight + 20
  height: implicitHeight

  Rectangle {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: 2
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
    anchors.margins: 10
    anchors.leftMargin: 14
    anchors.rightMargin: 28
    spacing: 10

    Column {
      width: hasImage ? parent.width - 58 : parent.width
      spacing: 8

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
            color: Wallust.base04
            font.family: "Symbols Nerd Font Mono"
            font.pixelSize: 16
          }
        }

        Text {
          anchors.left: parent.left
          anchors.leftMargin: 32
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          text: root.notification ? (root.notification.appName || root.notification.desktopEntry || "APP") : "APP"
          elide: Text.ElideRight
          color: Wallust.base05
          font.family: "Roboto Mono"
          font.pixelSize: 10
          font.bold: true
        }
      }

      Text {
        width: parent.width
        text: root.notification ? root.notification.summary : ""
        elide: Text.ElideRight
        color: Wallust.base05
        font.family: "Roboto Mono"
        font.pixelSize: compact ? 11 : 12
        font.bold: true
      }

      Text {
        width: parent.width
        text: root.relativeTime()
        color: Wallust.base04
        font.family: "Roboto Mono"
        font.pixelSize: 10
        font.bold: true
      }

      Text {
        width: parent.width
        visible: text !== ""
        wrapMode: Text.Wrap
        textFormat: Text.RichText
        text: root.notification ? (root.notification.body || "") : ""
        color: Wallust.base04
        font.family: "Roboto Mono"
        font.pixelSize: 10
      }

      Row {
        visible: repeater.count > 0
        spacing: 8

        Repeater {
          id: repeater
          model: root.actionButtons()

          Rectangle {
            required property var modelData

            width: Math.max(72, actionLabel.implicitWidth + 14)
            height: 28
            color: "transparent"
            border.width: 2
            border.color: Wallust.base03

            Text {
              id: actionLabel
              anchors.centerIn: parent
              text: modelData.text
              color: Wallust.base05
              font.family: "Roboto Mono"
              font.pixelSize: 10
              font.bold: true
            }

            MouseArea {
              anchors.fill: parent
              onClicked: modelData.invoke()
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
    anchors.topMargin: 8
    anchors.rightMargin: 8
    width: 18
    height: 18
    visible: root.closeVisible
    color: "transparent"
    border.width: 2
    border.color: Wallust.base03

    Text {
      anchors.centerIn: parent
      text: "󰅖"
      color: Wallust.base05
      font.family: "Symbols Nerd Font Mono"
      font.pixelSize: 10
    }

    MouseArea {
      anchors.fill: parent
      onClicked: Notif.NotificationServer.dismissOne(root.notification)
    }
  }
}
