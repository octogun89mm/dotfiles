import Quickshell
import QtQuick

// Flat swaybar-like bar, docked flush to the top edge.
// No per-module boxes, no hairline dividers — just a 1px bottom border.
Variants {
  model: Quickshell.screens

  PanelWindow {
    id: barWindow
    required property var modelData
    readonly property int screenIndex: Quickshell.screens.indexOf(modelData)
    readonly property color accentColor: Theme.monitorAccent(screenIndex)

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

      // 1px bottom border, subtle
      Rectangle {
        anchors {
          bottom: parent.bottom
          left: parent.left
          right: parent.right
        }
        height: Theme.hairline
        color: Theme.border
      }

      // LEFT cluster: monitor badge, this monitor's workspaces, active window title
      Row {
        id: leftCluster
        anchors {
          left: parent.left
          top: parent.top
          bottom: parent.bottom
        }
        spacing: 0

        MonitorBadge {
          screenIndex: barWindow.screenIndex
          accentColor: barWindow.accentColor
          anchors.verticalCenter: parent.verticalCenter
        }

        Workspaces {
          screenName: barWindow.modelData.name
          accentColor: barWindow.accentColor
          anchors.verticalCenter: parent.verticalCenter
        }

        Item {
          width: Theme.padLg
          height: 1
        }

        ActiveWindowTitle {
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      // RIGHT cluster: plain text modules, generous gaps, clock far right
      Row {
        anchors {
          right: parent.right
          top: parent.top
          bottom: parent.bottom
          rightMargin: Theme.padLg
        }
        spacing: Theme.gapLg

        TrayBlock {
          anchors.verticalCenter: parent.verticalCenter
        }

        MetricsBlock {
          anchors.verticalCenter: parent.verticalCenter
        }

        NetworkBlock {
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
