import QtQuick
import Quickshell

// Small square volume/mute OSD. No rounding, hard accent stripe, auto-hide.
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
      visible: root.visible
      exclusiveZone: 0

      anchors {
        bottom: true
        left: true
        right: true
      }

      margins {
        bottom: 40
      }

      implicitHeight: osdCard.implicitHeight

      Rectangle {
        id: osdCard
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        radius: 0
        color: Theme.bg
        border.width: Theme.hairline
        border.color: Theme.border
        implicitWidth: content.implicitWidth + Theme.padLg * 2 + Theme.stripe
        implicitHeight: Theme.barHeight + Theme.padSm * 2

        // Top accent stripe
        Rectangle {
          anchors {
            top: parent.top
            left: parent.left
            right: parent.right
          }
          height: Theme.stripe
          color: Theme.accent
        }

        Row {
          id: content
          anchors.centerIn: parent
          spacing: Theme.padMd

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: OsdState.icon
            color: Theme.accent
            font.family: Theme.iconFamily
            font.pixelSize: Theme.fontLg + 2
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: OsdState.text
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontMd
            font.bold: true
            font.letterSpacing: 0.4
          }
        }
      }
    }
  }
}
