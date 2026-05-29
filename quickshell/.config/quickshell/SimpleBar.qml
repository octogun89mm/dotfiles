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
            id: leftCluster
            anchors.left: parent.left
            anchors.leftMargin: Theme.padMd
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.padMd

            LayoutIndicator {
              monitorName: barWindow.modelData.name
              monitorId: String(barWindow.modelData.id)
            }

          }

          Item {
            id: leftGap
            anchors.left: leftCluster.right
            anchors.right: centerCluster.left
            anchors.verticalCenter: parent.verticalCenter
            height: 1
          }

          // CENTER cluster
          Row {
            id: centerCluster
            anchors.centerIn: parent
            spacing: Theme.padMd

            SimpleClock {
              id: centerClock
              anchors.verticalCenter: parent.verticalCenter
              pinned: barWindow.localPinned
              onClicked: {
                if (barWindow.localPinned)
                  scope.pinnedScreen = null
                else
                  scope.pinnedScreen = barWindow.modelData
              }
            }
          }

          // RIGHT cluster
          Row {
            anchors.right: parent.right
            anchors.rightMargin: Theme.padMd
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.padMd

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: BarDetailState.level === BarDetailState.minLevel ? "‹" : "›"
              color: vitalsHandleArea.containsMouse ? Theme.text : Theme.textDim
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSmall + 2
              Behavior on color { ColorAnimation { duration: 120 } }

              MouseArea {
                id: vitalsHandleArea
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: BarDetailState.toggleCollapsed()
              }
            }

            Item {
              id: metricsBox
              anchors.verticalCenter: parent.verticalCenter
              readonly property bool collapsed: BarDetailState.level === 0
              clip: true
              implicitHeight: Theme.chipHeight
              implicitWidth: collapsed ? 0 : metricsRow.implicitWidth
              opacity: collapsed ? 0 : 1
              scale: collapsed ? 0.4 : 1
              transformOrigin: Item.Right

              Behavior on implicitWidth {
                NumberAnimation { duration: 480; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
              }
              Behavior on opacity {
                NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
              }
              Behavior on scale {
                NumberAnimation { duration: 480; easing.type: Easing.OutBack; easing.overshoot: 2.4 }
              }

              MouseArea {
                anchors.fill: parent
                z: 10
                enabled: !metricsBox.collapsed
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onClicked: BarDetailState.cycleDetails()
              }

              Row {
                id: metricsRow
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                spacing: Theme.padXs

                InlineMetric {
                  anchors.verticalCenter: parent.verticalCenter
                  label: "CPU"
                  value: MetricsState.cpuUsage >= 0
                    ? String(Math.round(MetricsState.cpuUsage)).padStart(2, "0") + "%"
                    : "--"
                  history: MetricsState.cpuHistory
                  accentColor: Theme.accent
                  detail: (MetricsState.cpuTemp >= 0 ? Math.round(MetricsState.cpuTemp) + "C" : "")
                    + (MetricsState.load1 >= 0 ? " L" + MetricsState.load1.toFixed(2) : "")
                  showDetail: BarDetailState.level >= 2
                  showGraph: BarDetailState.level >= 3
                  graphWidth: 80
                  Behavior on graphWidth { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
                }

                CpuGovernor {
                  anchors.verticalCenter: parent.verticalCenter
                  visible: BarDetailState.level >= 2
                }

                InlineMetric {
                  anchors.verticalCenter: parent.verticalCenter
                  label: "MEM"
                  value: MetricsState.memPercent >= 0
                    ? String(Math.round(MetricsState.memPercent)).padStart(2, "0") + "%"
                    : "--"
                  history: MetricsState.memHistory
                  accentColor: Theme.accentAlt
                  detail: MetricsState.memUsed >= 0 && MetricsState.memTotal > 0
                    ? MetricsState.memUsed.toFixed(1) + "/" + MetricsState.memTotal.toFixed(1) + "G"
                    : ""
                  showDetail: BarDetailState.level >= 2
                  showGraph: BarDetailState.level >= 3
                  graphWidth: 80
                  Behavior on graphWidth { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
                }

                InlineMetric {
                  anchors.verticalCenter: parent.verticalCenter
                  label: "GPU"
                  value: MetricsState.gpuUsage >= 0
                    ? String(Math.round(MetricsState.gpuUsage)).padStart(2, "0") + "%"
                    : "--"
                  history: MetricsState.gpuHistory
                  accentColor: Theme.success
                  detail: (MetricsState.gpuTemp >= 0 ? Math.round(MetricsState.gpuTemp) + "C" : "")
                    + (MetricsState.gpuVramTotalGb > 0 ? " " + MetricsState.gpuVramUsedGb.toFixed(1) + "/" + MetricsState.gpuVramTotalGb.toFixed(0) + "G" : "")
                  showDetail: BarDetailState.level >= 2
                  showGraph: BarDetailState.level >= 3
                  graphWidth: 80
                  Behavior on graphWidth { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
                }
              }
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

          // LEFT cluster — indicators
          Row {
            anchors.left: parent.left
            anchors.leftMargin: Theme.padMd
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.padSm

            Tailscale { anchors.verticalCenter: parent.verticalCenter }
            Vpn { anchors.verticalCenter: parent.verticalCenter; onlyWhenActive: true }
            IdleInhibitor { anchors.verticalCenter: parent.verticalCenter; onlyWhenActive: true }
            MicIndicator { anchors.verticalCenter: parent.verticalCenter; onlyWhenActive: true }
            Jubotai { anchors.verticalCenter: parent.verticalCenter }
            JubotaiConvo { anchors.verticalCenter: parent.verticalCenter }
            SuspendIndicator { anchors.verticalCenter: parent.verticalCenter; onlyWhenDisabled: false }
          }

          Row {
            id: workspaceSegment
            anchors.centerIn: parent
            spacing: Theme.padSm

            SimpleWorkspace {
              anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: Theme.hairline
              height: 12
              color: Theme.border
              opacity: trayInWorkspace.implicitWidth > 0 ? 1 : 0
              Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              implicitWidth: trayInWorkspace.implicitWidth + Theme.padSm * 2
              implicitHeight: Theme.chipHeight
              color: trayHover.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06) : "transparent"

              Tray {
                id: trayInWorkspace
                anchors.centerIn: parent
                showToggle: false
                expanded: true
                iconColor: Theme.textDim
                iconSize: 12
                spacing: 4
                symbolicIcons: true
              }

              MouseArea {
                id: trayHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
              }
            }
          }

          // RIGHT cluster — media + language
          Row {
            anchors.right: parent.right
            anchors.rightMargin: Theme.padMd
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.padMd

            Item {
              anchors.verticalCenter: parent.verticalCenter
              visible: ThemeNameState.name !== ""
              implicitWidth: themeNameText.implicitWidth
              implicitHeight: themeNameText.implicitHeight

              Text {
                id: themeNameText
                anchors.fill: parent
                text: ThemeNameState.name
                color: themeNameMouse.containsMouse ? Theme.text : Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.italic: true
                verticalAlignment: Text.AlignVCenter
                Behavior on color { ColorAnimation { duration: 120 } }
              }

              MouseArea {
                id: themeNameMouse
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ThemePickerState.show(barWindow.modelData.name)
              }
            }


            KeyboardLayout { anchors.verticalCenter: parent.verticalCenter }
          }
        }
      }

      Popup.PopupShell {
        shellParentWindow: barWindow
        triggerItem: row1
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
