import Quickshell
import QtQuick

// Full-width bar, docked flush to the top edge (matches classic Bar.qml).
// No outer margins, no rounding — square brutalist blocks separated by
// hairline dividers, with a 2px accent line along the bottom edge.
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

      // 2px accent line along the bar's inner edge (bottom, facing workspace)
      Rectangle {
        anchors {
          bottom: parent.bottom
          left: parent.left
          right: parent.right
        }
        height: Theme.stripe
        color: Theme.borderActive
      }

      // LEFT cluster
      Row {
        id: leftCluster
        anchors {
          left: parent.left
          top: parent.top
          bottom: parent.bottom
        }
        spacing: 0

        Workspaces {
          screenName: barWindow.modelData.name
        }

        Block {
          dividerLeft: true
          ActiveWindowTitle {}
        }
      }

      // CENTER cluster
      Row {
        anchors.centerIn: parent
        spacing: 0

        Block {
          dividerLeft: true
          dividerRight: true
          ClockBlock {}
        }

        Block {
          dividerRight: true
          DateBlock {}
        }
      }

      // RIGHT cluster
      Row {
        anchors {
          right: parent.right
          top: parent.top
          bottom: parent.bottom
        }
        spacing: 0
        layoutDirection: Qt.RightToLeft

        Block {
          dividerLeft: true
          VolumeBlock {}
        }

        Block {
          dividerLeft: true
          KeyboardBlock {}
        }

        Block {
          dividerLeft: true
          collapsed: !MicState.active
          accentTop: true
          accentColor: Theme.critical
          MicBlock {}
        }

        Block {
          dividerLeft: true
          NetworkBlock {}
        }

        Block {
          dividerLeft: true
          MetricsBlock {}
        }

        Block {
          dividerLeft: true
          TrayBlock {}
        }
      }
    }
  }
}
