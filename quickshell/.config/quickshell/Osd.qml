import QtQuick
import Quickshell
import "wallust.js" as Wallust

Scope {
  id: root

  property bool visible: OsdState.visible

  Timer {
    id: hideTimer
    interval: 1500
    repeat: false
    onTriggered: OsdState.hide()
  }

  Connections {
    target: OsdState

    function onRevisionChanged() {
      hideTimer.restart()
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData

      screen: modelData
      color: "transparent"
      visible: root.visible || slideAnim.running || fadeAnim.running
      exclusiveZone: 0

      anchors {
        bottom: true
        left: true
        right: true
      }

      margins {
        bottom: 10
      }

      implicitHeight: osdCard.implicitHeight

      Rectangle {
        id: osdCard
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.visible ? 0 : 18
        opacity: root.visible ? 1 : 0
        color: Wallust.base00
        border.width: 2
        border.color: Wallust.accent
        implicitWidth: content.implicitWidth + 20
        implicitHeight: content.implicitHeight + 14

        Behavior on y {
          NumberAnimation {
            id: slideAnim
            duration: 150
            easing.type: Easing.OutQuad
          }
        }

        Behavior on opacity {
          NumberAnimation {
            id: fadeAnim
            duration: 150
            easing.type: Easing.OutQuad
          }
        }

        Row {
          id: content
          anchors.centerIn: parent
          spacing: 10

          Text {
            text: OsdState.icon
            color: Wallust.accent
            font.family: "Symbols Nerd Font Mono"
            font.pixelSize: 18
          }

          Text {
            text: OsdState.text
            color: Wallust.base05
            font.family: "Roboto Mono"
            font.pixelSize: 13
            font.bold: true
          }
        }
      }
    }
  }
}
