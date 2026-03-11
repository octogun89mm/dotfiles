import Quickshell
import Quickshell.Io
import QtQuick
import "wallust.js" as Wallust
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

      margins {
        top: 5
        left: 10
        right: 10
      }

      implicitHeight: 24

      Rectangle {
        anchors.fill: parent
        color: Wallust.base00
        border.width: 2
        border.color: Wallust.base03

        Row {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8

          LayoutIndicator {
            monitorName: barWindow.modelData.name
            monitorId: String(barWindow.modelData.id)
          }

          Workspace {}
        }

        Sound {
          id: soundIndicator
          anchors.right: vpnIndicator.left
          anchors.rightMargin: 4
          anchors.verticalCenter: centerClock.verticalCenter
        }

        Vpn {
          id: vpnIndicator
          anchors.right: centerClock.left
          anchors.rightMargin: 4
          anchors.verticalCenter: centerClock.verticalCenter
        }

        Clock {
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

        IdleInhibitor {
          id: idleIndicator
          anchors.left: centerClock.right
          anchors.leftMargin: 4
          anchors.verticalCenter: centerClock.verticalCenter
        }

        KeyboardLayout {
          anchors.left: idleIndicator.right
          anchors.leftMargin: 4
          anchors.verticalCenter: centerClock.verticalCenter
        }

        Row {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8

          Tray {
            anchors.verticalCenter: parent.verticalCenter
          }

          Date {
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

      Popup.PopupShell {
        shellParentWindow: barWindow
        triggerItem: centerClock
        pinned: barWindow.localPinned
        triggerHovered: centerClock.hovered
      }

      Popup.CalendarPopup {
        shellParentWindow: barWindow
        triggerItem: dateWidget
        pinned: barWindow.localCalendarPinned
        triggerHovered: dateWidget.hovered
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
