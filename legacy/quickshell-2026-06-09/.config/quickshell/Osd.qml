import QtQuick
import Quickshell

Scope {
  id: root

  property bool visible: OsdState.visible

  Timer {
    id: hideTimer
    interval: 1200
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
        bottom: 24
      }

      implicitHeight: osdCard.implicitHeight

      Rectangle {
        id: osdCard
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.visible ? 0 : 18
        opacity: root.visible ? 1 : 0
        color: Theme.surface
        border.width: Theme.hairline
        border.color: Theme.border
        implicitWidth: content.implicitWidth + Theme.padLg * 2 + Theme.stripe
        implicitHeight: 28

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

        // Left accent stripe
        Rectangle {
          anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
          }
          width: Theme.stripe
          color: Theme.accent
        }

        Row {
          id: content
          anchors.verticalCenter: parent.verticalCenter
          anchors.left: parent.left
          anchors.leftMargin: Theme.stripe + Theme.padLg
          spacing: Theme.padMd

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: OsdState.icon
            color: Theme.accent
            font.family: Theme.iconFamily
            font.pixelSize: Theme.fontTitle + 2
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: OsdState.text
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            font.bold: true
            font.letterSpacing: 0.4
          }
        }
      }
    }
  }
}
