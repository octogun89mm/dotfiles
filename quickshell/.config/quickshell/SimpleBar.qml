import Quickshell
import Quickshell.Io
import QtQuick
import "popup" as Popup

Scope {
  id: scope
  property var pinnedScreen: null
  property var calendarPinnedScreen: null

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: barWindow
      required property var modelData
      screen: modelData
      color: "transparent"

      readonly property bool localPinned: scope.pinnedScreen === modelData
      readonly property bool localCalendarPinned: scope.calendarPinnedScreen === modelData

      anchors {
        top: true
        left: true
        right: true
      }

      implicitHeight: Theme.barHeight

      Rectangle {
        id: barBg
        anchors.fill: parent
        color: Theme.bg

        // ───────── ROW 1 — IDENTITY + NOW ─────────
        Item {
          id: row1
          anchors {
            left: parent.left
            right: parent.right
            top: parent.top
          }
          height: Theme.rowHeight

          // LEFT cluster
          Row {
            anchors.left: parent.left
            anchors.leftMargin: Theme.padMd
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.padMd

            LayoutIndicator {
              monitorName: barWindow.modelData.name
              monitorId: String(barWindow.modelData.id)
            }

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: 1
              height: 10
              color: Theme.border
            }

            SimpleWorkspace {}

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: 1
              height: 10
              color: Theme.border
            }

            ActiveWindowTitle {
              anchors.verticalCenter: parent.verticalCenter
              maxWidth: 260
            }
          }

          // CENTER cluster
          SimpleClock {
            id: centerClock
            anchors.centerIn: parent
            pinned: barWindow.localPinned
            onClicked: {
              if (barWindow.localPinned)
                scope.pinnedScreen = null
              else
                scope.pinnedScreen = barWindow.modelData
            }
          }

          // RIGHT cluster
          Row {
            anchors.right: parent.right
            anchors.rightMargin: Theme.padMd
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.padMd

            MicIndicator { anchors.verticalCenter: parent.verticalCenter; onlyWhenActive: true }
            IdleInhibitor { anchors.verticalCenter: parent.verticalCenter; onlyWhenActive: true }
            Vpn { anchors.verticalCenter: parent.verticalCenter; onlyWhenActive: true }

            Tray {
              anchors.verticalCenter: parent.verticalCenter
              showToggle: false
              expanded: true
              iconColor: Theme.text
            }

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: 1
              height: 10
              color: Theme.border
            }

            SimpleDate {
              id: dateWidget
              anchors.verticalCenter: parent.verticalCenter
              pinned: barWindow.localCalendarPinned
              onClicked: {
                if (barWindow.localCalendarPinned)
                  scope.calendarPinnedScreen = null
                else
                  scope.calendarPinnedScreen = barWindow.modelData
              }
            }
          }
        }

        // ───────── ROW 2 — AMBIENT + LIVE ─────────
        Item {
          id: row2
          anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
          }
          height: Theme.rowHeight

          // LEFT cluster — system metrics
          Row {
            anchors.left: parent.left
            anchors.leftMargin: Theme.padMd
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.padSm

            SimpleWindowCount {
              monitorName: barWindow.modelData.name
            }

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: 1; height: 10; color: Theme.border
            }

            InlineMetric {
              anchors.verticalCenter: parent.verticalCenter
              label: "CPU"
              value: MetricsState.cpuUsage >= 0
                ? String(Math.round(MetricsState.cpuUsage)).padStart(2, "0") + "%"
                : "--"
              history: MetricsState.cpuHistory
              accentColor: Theme.accent
            }

            InlineMetric {
              anchors.verticalCenter: parent.verticalCenter
              label: "MEM"
              value: MetricsState.memPercent >= 0
                ? String(Math.round(MetricsState.memPercent)).padStart(2, "0") + "%"
                : "--"
              history: MetricsState.memHistory
              accentColor: Theme.accentAlt
            }

            InlineMetric {
              anchors.verticalCenter: parent.verticalCenter
              label: "GPU"
              value: MetricsState.gpuUsage >= 0
                ? String(Math.round(MetricsState.gpuUsage)).padStart(2, "0") + "%"
                : "--"
              history: MetricsState.gpuHistory
              accentColor: Theme.success
            }
          }

          // CENTER cluster — cava visualizer
          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.padMd

            CavaBars {
              anchors.verticalCenter: parent.verticalCenter
              mirrored: true
              channel: "left"
              implicitWidth: 80
            }

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: 1
              height: 10
              color: Theme.border
            }

            CavaBars {
              anchors.verticalCenter: parent.verticalCenter
              channel: "right"
              implicitWidth: 80
            }
          }

          // RIGHT cluster — media + language
          Row {
            anchors.right: parent.right
            anchors.rightMargin: Theme.padMd
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.padMd

            MediaChip { anchors.verticalCenter: parent.verticalCenter }
            KeyboardLayout { anchors.verticalCenter: parent.verticalCenter }
          }
        }
      }

      Popup.PopupShell {
        shellParentWindow: barWindow
        triggerItem: centerClock
        pinned: barWindow.localPinned
        triggerHovered: false
      }

      Popup.CalendarPopup {
        shellParentWindow: barWindow
        triggerItem: dateWidget
        pinned: barWindow.localCalendarPinned
        triggerHovered: false
      }
    }
  }

  IpcHandler {
    target: "bar"

    function togglePopup(monitorName: string): void {
      if (scope.pinnedScreen !== null) {
        scope.pinnedScreen = null
      } else {
        for (var i = 0; i < Quickshell.screens.length; i++) {
          if (Quickshell.screens[i].name === monitorName) {
            scope.pinnedScreen = Quickshell.screens[i]
            return
          }
        }
      }
    }
  }
}
