import Quickshell
import QtQuick

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

      // RIGHT cluster: plain text modules, generous gaps, clock far right
      Row {
        anchors {
          right: parent.right
          top: parent.top
          bottom: parent.bottom
          rightMargin: Theme.padMd
        }
        spacing: Theme.gapLg

        TrayBlock {
          anchors.verticalCenter: parent.verticalCenter
        }

        MetricsBlock {
          anchors.verticalCenter: parent.verticalCenter
        }

        NetSpeedBlock {
          anchors.verticalCenter: parent.verticalCenter
        }

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

        Clock {
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }
}
