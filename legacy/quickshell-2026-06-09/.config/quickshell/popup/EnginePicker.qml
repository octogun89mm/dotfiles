import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".." as Root

Scope {
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: pickerWindow
      required property var modelData

      screen: modelData
      color: "transparent"
      exclusiveZone: 0
      readonly property bool activeScreen: Root.EnginePickerState.screenName === modelData.name
      readonly property bool overlayVisible: Root.EnginePickerState.visible && activeScreen

      visible: overlayVisible || slideAnim.running
      WlrLayershell.keyboardFocus: overlayVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: pickerWindow.overlayVisible
        onActivated: Root.EnginePickerState.hide()
      }

      Shortcut {
        sequence: "Down"
        context: Qt.WindowShortcut
        enabled: pickerWindow.overlayVisible
        onActivated: Root.EnginePickerState.moveSelection(1)
      }

      Shortcut {
        sequence: "Up"
        context: Qt.WindowShortcut
        enabled: pickerWindow.overlayVisible
        onActivated: Root.EnginePickerState.moveSelection(-1)
      }

      Shortcut {
        sequence: "Return"
        context: Qt.WindowShortcut
        enabled: pickerWindow.overlayVisible
        onActivated: Root.EnginePickerState.activateSelection()
      }

      Shortcut {
        sequence: "Enter"
        context: Qt.WindowShortcut
        enabled: pickerWindow.overlayVisible
        onActivated: Root.EnginePickerState.activateSelection()
      }

      MouseArea {
        anchors.fill: parent
        visible: pickerWindow.overlayVisible
        onClicked: Root.EnginePickerState.hide()
      }

      Rectangle {
        id: panel

        width: 460
        height: contentColumn.implicitHeight + 2 * Root.Theme.padLg
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 10
        color: Root.Theme.bg
        border.width: Root.Theme.stripe
        border.color: Root.Theme.accent

        transform: Translate {
          y: pickerWindow.overlayVisible ? 0 : -(panel.height + 12)

          Behavior on y {
            NumberAnimation {
              id: slideAnim
              duration: 200
              easing.type: Easing.OutQuad
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.NoButton
        }

        Column {
          id: contentColumn
          anchors.fill: parent
          anchors.margins: Root.Theme.padLg
          spacing: Root.Theme.padLg

          Text {
            text: "SPEAK · PICK ENGINE"
            color: Root.Theme.textMuted
            font.family: Root.Theme.fontFamily
            font.pixelSize: Root.Theme.fontCaption
            font.bold: true
          }

          Rectangle {
            width: parent.width
            height: Math.min(72, previewText.implicitHeight + 2 * Root.Theme.padMd)
            color: Root.Theme.surface
            border.width: Root.Theme.stripe
            border.color: Root.Theme.border

            Text {
              id: previewText
              anchors.fill: parent
              anchors.margins: Root.Theme.padMd
              text: Root.EnginePickerState.text
              color: Root.Theme.text
              font.family: Root.Theme.fontFamily
              font.pixelSize: Root.Theme.fontSmall
              wrapMode: Text.Wrap
              elide: Text.ElideRight
              maximumLineCount: 3
            }
          }

          Repeater {
            model: Root.EnginePickerState.engines

            delegate: Rectangle {
              id: engineRow
              required property int index
              required property var model
              readonly property bool selected: Root.EnginePickerState.selectedIndex === index

              width: contentColumn.width
              height: 38
              color: selected ? Root.Theme.accent : "transparent"
              border.width: Root.Theme.hairline
              border.color: selected ? Root.Theme.accent : Root.Theme.border

              Text {
                id: nameText
                anchors.left: parent.left
                anchors.leftMargin: Root.Theme.padMd
                anchors.top: parent.top
                anchors.topMargin: 4
                text: engineRow.model.name
                color: engineRow.selected ? Root.Theme.bg : Root.Theme.text
                font.family: Root.Theme.fontFamily
                font.pixelSize: Root.Theme.fontBody
                font.bold: true
              }

              Text {
                anchors.left: parent.left
                anchors.leftMargin: Root.Theme.padMd
                anchors.top: nameText.bottom
                text: engineRow.model.subtitle
                color: engineRow.selected ? Root.Theme.bg : Root.Theme.textMuted
                font.family: Root.Theme.fontFamily
                font.pixelSize: Root.Theme.fontCaption
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: Root.EnginePickerState.selectedIndex = engineRow.index
                onClicked: Root.EnginePickerState.apply(engineRow.model.flags)
              }
            }
          }
        }
      }
    }
  }

  IpcHandler {
    target: "speak"

    function open(text: string, monitorName: string): void {
      Root.EnginePickerState.show(text, monitorName)
    }

    function hide(): void {
      Root.EnginePickerState.hide()
    }
  }
}
