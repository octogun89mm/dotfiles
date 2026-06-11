import Quickshell
import QtQuick
import "." as Square

// Flat swaybar-like bar, docked flush to the top edge.
// No per-module boxes, no hairline dividers, no borders.
Variants {
  model: Quickshell.screens

  PanelWindow {
    id: barWindow
    required property var modelData

    screen: modelData
    color: "transparent"

    anchors {
      top: true
      left: true
      right: true
    }

    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight

    Rectangle {
      id: barBg
      anchors.fill: parent
      color: Theme.bg
      radius: 0

      // LEFT cluster: workspaces (all monitors, colour-coded)
      Workspaces {
        anchors {
          left: parent.left
          verticalCenter: parent.verticalCenter
        }
      }

      // CENTER: clock and date
      Clock {
        anchors.centerIn: parent
      }

      // RIGHT cluster: compact status groups
      Row {
        anchors {
          right: parent.right
          top: parent.top
          bottom: parent.bottom
          rightMargin: Theme.padMd
      }
        spacing: Theme.padLg

        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: Theme.padMd

          Square.TmuxSessions {
            anchors.verticalCenter: parent.verticalCenter
          }

          Square.NotificationBlock {
            anchors.verticalCenter: parent.verticalCenter
            screenName: barWindow.modelData.name
          }

          TrayBlock {
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: Theme.hairline
          height: 12
          color: Theme.border
        }

        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: Theme.padMd

          MetricsBlock {
            anchors.verticalCenter: parent.verticalCenter
          }

          NetSpeedBlock {
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: Theme.hairline
          height: 12
          color: Theme.border
        }

        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: Theme.padMd

          MicBlock {
            visible: MicState.active
            anchors.verticalCenter: parent.verticalCenter
          }

          KeyboardBlock {
            anchors.verticalCenter: parent.verticalCenter
          }

          VolumeBlock {
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }
    }
  }
}
