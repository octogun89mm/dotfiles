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

      implicitHeight: 24

      Rectangle {
        anchors.fill: parent
        color: Wallust.base00

        Row {
          anchors.left: parent.left
          anchors.leftMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          spacing: 10

          LayoutIndicator {
            monitorName: barWindow.modelData.name
            monitorId: String(barWindow.modelData.id)
            compact: false
            borderless: true
          }

          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 12
            color: Wallust.base02
          }

          SimpleWindowCount {
            monitorName: barWindow.modelData.name
          }

          SimpleWorkspace {}
        }

        SimpleClock {
          id: centerClock
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          pinned: barWindow.localPinned
          onClicked: {
            if (barWindow.localPinned)
              scope.pinnedScreen = null
            else
              scope.pinnedScreen = barWindow.modelData
          }
        }

        Row {
          anchors.right: parent.right
          anchors.rightMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          spacing: 10

          Vpn {
            anchors.verticalCenter: parent.verticalCenter
            borderless: true
            onlyWhenActive: true
            activeColor: Wallust.base05
            inactiveColor: Wallust.base05
          }

          IdleInhibitor {
            anchors.verticalCenter: parent.verticalCenter
            borderless: true
            onlyWhenActive: true
            activeColor: Wallust.base05
            inactiveColor: Wallust.base05
          }

          Tray {
            anchors.verticalCenter: parent.verticalCenter
            showToggle: false
            expanded: true
            iconColor: Wallust.base05
          }

          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 12
            color: Wallust.base02
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
