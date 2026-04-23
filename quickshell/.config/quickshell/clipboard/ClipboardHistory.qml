import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "." as Clipboard
import "../wallust.js" as Wallust

Scope {
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: clipboardWindow
      required property var modelData

      screen: modelData
      color: "transparent"
      exclusiveZone: 0
      readonly property bool activeScreen: Clipboard.ClipboardState.screenName === modelData.name
      readonly property bool overlayVisible: Clipboard.ClipboardState.visible && activeScreen
      readonly property int minPanelHeight: 300
      readonly property int maxPanelHeight: Math.max(minPanelHeight, modelData.height - 20)
      readonly property int desiredPanelHeight: headerRow.implicitHeight + filterBox.height + 52
        + (historyList.visible ? historyList.contentHeight : emptyState.implicitHeight + 24)

      visible: (overlayVisible) || slideAnim.running
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
        enabled: clipboardWindow.overlayVisible
        onActivated: {
          if (filterInput.text !== "") {
            filterInput.text = ""
          } else {
            Clipboard.ClipboardState.hide()
          }
        }
      }

      Shortcut {
        sequence: "Down"
        context: Qt.WindowShortcut
        enabled: clipboardWindow.overlayVisible && historyList.count > 0
        onActivated: clipboardWindow.moveSelection(1)
      }

      Shortcut {
        sequence: "Up"
        context: Qt.WindowShortcut
        enabled: clipboardWindow.overlayVisible && historyList.count > 0
        onActivated: clipboardWindow.moveSelection(-1)
      }

      Shortcut {
        sequence: "Return"
        context: Qt.WindowShortcut
        enabled: clipboardWindow.overlayVisible
        onActivated: clipboardWindow.activateSelection()
      }

      Shortcut {
        sequence: "Enter"
        context: Qt.WindowShortcut
        enabled: clipboardWindow.overlayVisible
        onActivated: clipboardWindow.activateSelection()
      }

      Shortcut {
        sequence: "Delete"
        context: Qt.WindowShortcut
        enabled: clipboardWindow.overlayVisible
        onActivated: clipboardWindow.deleteSelection()
      }

      MouseArea {
        anchors.fill: parent
        visible: clipboardWindow.overlayVisible
        onClicked: Clipboard.ClipboardState.hide()
      }

      Rectangle {
        id: panel

        width: 480
        height: Math.min(clipboardWindow.maxPanelHeight, Math.max(clipboardWindow.minPanelHeight, clipboardWindow.desiredPanelHeight))
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 10
        color: Wallust.base00
        border.width: 2
        border.color: Wallust.accent

        transform: Translate {
          y: clipboardWindow.overlayVisible ? 0 : -(panel.height + 12)

          Behavior on y {
            NumberAnimation {
              id: slideAnim
              duration: 200
              easing.type: Easing.OutQuad
            }
          }
        }

        Column {
          anchors.fill: parent
          anchors.margins: 12
          spacing: 12

          Item {
            id: headerRow
            width: parent.width
            height: 24

            Text {
              id: titleLabel
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: "CLIPBOARD"
              color: Wallust.base04
              font.family: "Iosevka"
              font.pixelSize: 10
              font.bold: true
            }

            Rectangle {
              anchors.left: titleLabel.right
              anchors.leftMargin: 8
              anchors.verticalCenter: parent.verticalCenter
              width: Math.max(24, countLabel.implicitWidth + 10)
              height: 20
              color: "transparent"
              border.width: 2
              border.color: Wallust.accent

              Text {
                id: countLabel
                anchors.centerIn: parent
                text: Clipboard.ClipboardState.entries.count
                color: Wallust.base05
                font.family: "Iosevka"
                font.pixelSize: 10
                font.bold: true
              }
            }

            Rectangle {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              width: wipeLabel.implicitWidth + 14
              height: 24
              color: "transparent"
              border.width: 2
              border.color: Wallust.base01

              Text {
                id: wipeLabel
                anchors.centerIn: parent
                text: "WIPE"
                color: Wallust.base05
                font.family: "Iosevka"
                font.pixelSize: 10
                font.bold: true
              }

              MouseArea {
                anchors.fill: parent
                onClicked: Clipboard.ClipboardState.wipeAll()
              }
            }
          }

          Rectangle {
            id: filterBox
            width: parent.width
            height: 34
            color: Wallust.base01
            border.width: 2
            border.color: filterInput.activeFocus ? Wallust.accent : Wallust.base03

            TextInput {
              id: filterInput
              anchors.fill: parent
              anchors.margins: 8
              color: Wallust.base05
              font.family: "Iosevka"
              font.pixelSize: 11
              clip: true
              selectByMouse: true
              selectedTextColor: Wallust.base00
              selectionColor: Wallust.accent
              onTextChanged: Clipboard.ClipboardState.setFilterText(text)
            }

            Text {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: 8
              visible: filterInput.text === "" && !filterInput.activeFocus
              text: "FILTER"
              color: Wallust.base03
              font.family: "Iosevka"
              font.pixelSize: 11
            }
          }

          Item {
            width: parent.width
            height: parent.height - y

            ListView {
              id: historyList
              anchors.fill: parent
              clip: true
              spacing: 8
              model: Clipboard.ClipboardState.filteredEntries
              currentIndex: count > 0 ? 0 : -1
              visible: count > 0

              delegate: Clipboard.ClipboardItem {
                width: historyList.width
                selected: ListView.isCurrentItem
              }
            }

            Column {
              id: emptyState
              anchors.centerIn: parent
              spacing: 8
              visible: !historyList.visible

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰅌"
                color: Wallust.base03
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 24
              }

              Text {
                text: "CLIPBOARD EMPTY"
                color: Wallust.base03
                font.family: "Iosevka"
                font.pixelSize: 11
                font.bold: true
              }
            }
          }
        }
      }

      Timer {
        id: focusTimer
        interval: 50
        repeat: false
        onTriggered: filterInput.forceActiveFocus()
      }

      onOverlayVisibleChanged: {
        if (overlayVisible) focusTimer.restart()
        else filterInput.text = ""
      }

      function ensureValidSelection() {
        if (historyList.count === 0) {
          historyList.currentIndex = -1
          return
        }

        if (historyList.currentIndex < 0 || historyList.currentIndex >= historyList.count) {
          historyList.currentIndex = 0
        }
      }

      function moveSelection(delta) {
        ensureValidSelection()
        if (historyList.count === 0) return

        const nextIndex = Math.max(0, Math.min(historyList.count - 1, historyList.currentIndex + delta))
        historyList.currentIndex = nextIndex
        historyList.positionViewAtIndex(nextIndex, ListView.Contain)
      }

      function activateSelection() {
        ensureValidSelection()
        if (historyList.currentIndex < 0) return

        const entry = Clipboard.ClipboardState.filteredEntries.get(historyList.currentIndex)
        Clipboard.ClipboardState.select(entry.sourceIndex)
      }

      function deleteSelection() {
        ensureValidSelection()
        if (historyList.currentIndex < 0) return

        const entry = Clipboard.ClipboardState.filteredEntries.get(historyList.currentIndex)
        const nextIndex = historyList.currentIndex
        Clipboard.ClipboardState.deleteEntry(entry.sourceIndex)

        if (historyList.count === 0) {
          historyList.currentIndex = -1
        } else {
          historyList.currentIndex = Math.min(nextIndex, historyList.count - 1)
          historyList.positionViewAtIndex(historyList.currentIndex, ListView.Contain)
        }
      }

      Connections {
        target: Clipboard.ClipboardState.filteredEntries

        function onCountChanged() {
          clipboardWindow.ensureValidSelection()
        }
      }
    }
  }

  IpcHandler {
    target: "clipboard"

    function toggle(monitorName: string): void {
      Clipboard.ClipboardState.toggle(monitorName)
    }

    function hide(): void {
      Clipboard.ClipboardState.hide()
    }
  }
}
