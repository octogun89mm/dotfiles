import QtQuick
import Quickshell
import Quickshell.Wayland
import ".." as Root
import "../wallust.js" as Wallust

Scope {
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: pickerWindow
      required property var modelData

      screen: modelData
      color: "transparent"
      exclusiveZone: 0
      readonly property bool activeScreen: Root.ThemePickerState.screenName === modelData.name
      readonly property bool overlayVisible: Root.ThemePickerState.visible && activeScreen

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
        onActivated: {
          if (filterInput.text !== "") filterInput.text = ""
          else Root.ThemePickerState.hide()
        }
      }

      Shortcut {
        sequence: "Down"
        context: Qt.WindowShortcut
        enabled: pickerWindow.overlayVisible
        onActivated: Root.ThemePickerState.moveSelection(1)
      }

      Shortcut {
        sequence: "Up"
        context: Qt.WindowShortcut
        enabled: pickerWindow.overlayVisible
        onActivated: Root.ThemePickerState.moveSelection(-1)
      }

      Shortcut {
        sequence: "PgDown"
        context: Qt.WindowShortcut
        enabled: pickerWindow.overlayVisible
        onActivated: Root.ThemePickerState.moveSelection(10)
      }

      Shortcut {
        sequence: "PgUp"
        context: Qt.WindowShortcut
        enabled: pickerWindow.overlayVisible
        onActivated: Root.ThemePickerState.moveSelection(-10)
      }

      Shortcut {
        sequence: "Return"
        context: Qt.WindowShortcut
        enabled: pickerWindow.overlayVisible
        onActivated: Root.ThemePickerState.activateSelection()
      }

      Shortcut {
        sequence: "Enter"
        context: Qt.WindowShortcut
        enabled: pickerWindow.overlayVisible
        onActivated: Root.ThemePickerState.activateSelection()
      }

      MouseArea {
        anchors.fill: parent
        visible: pickerWindow.overlayVisible
        onClicked: Root.ThemePickerState.hide()
      }

      Rectangle {
        id: panel

        readonly property color panelBg: Wallust.base00
        readonly property color accent: Wallust.accent
        readonly property bool bgIsLight: (0.299 * panelBg.r + 0.587 * panelBg.g + 0.114 * panelBg.b) > 0.5
        readonly property color surface: bgIsLight ? Qt.darker(panelBg, 1.10) : Qt.lighter(panelBg, 1.6)
        readonly property color subtleBorder: bgIsLight ? Qt.darker(panelBg, 1.30) : Qt.lighter(panelBg, 2.2)
        readonly property color selectedBg: accent
        readonly property color selectedFg: panelBg
        readonly property color textColor: bgIsLight ? Qt.darker(panelBg, 6.0) : Qt.lighter(panelBg, 5.0)
        readonly property color textMuted: bgIsLight ? Qt.darker(panelBg, 2.8) : Qt.lighter(panelBg, 3.2)

        width: Root.ThemePickerState.mode === "wallpaper" ? 680 : 420
        height: 480
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 10
        color: panelBg
        border.width: 2
        border.color: accent

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
              text: Root.ThemePickerState.modeLabel
              color: panel.textMuted
              font.family: "Liberation Mono"
              font.pixelSize: 10
              font.bold: true
            }

            Rectangle {
              anchors.left: titleLabel.right
              anchors.leftMargin: 8
              anchors.verticalCenter: parent.verticalCenter
              width: Math.max(28, countLabel.implicitWidth + 10)
              height: 20
              color: "transparent"
              border.width: 2
              border.color: panel.accent

              Text {
                id: countLabel
                anchors.centerIn: parent
                text: Root.ThemePickerState.filteredThemes.count
                color: panel.textColor
                font.family: "Liberation Mono"
                font.pixelSize: 10
                font.bold: true
              }
            }

            Rectangle {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              width: modeLabel.implicitWidth + 18
              height: 20
              color: modeMouse.containsMouse ? panel.surface : "transparent"
              border.width: 2
              border.color: panel.subtleBorder

              Text {
                id: modeLabel
                anchors.centerIn: parent
                text: Root.ThemePickerState.mode === "wallpaper" ? "THEMES" : "WALLPAPERS"
                color: modeMouse.containsMouse ? panel.textColor : panel.textMuted
                font.family: "Liberation Mono"
                font.pixelSize: 10
                font.bold: true
              }

              MouseArea {
                id: modeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Root.ThemePickerState.toggleMode()
              }
            }
          }

          Rectangle {
            id: filterBox
            width: parent.width
            height: 34
            color: panel.surface
            border.width: 2
            border.color: filterInput.activeFocus ? panel.accent : panel.subtleBorder

            TextInput {
              id: filterInput
              anchors.fill: parent
              anchors.margins: 8
              color: panel.textColor
              font.family: "Liberation Mono"
              font.pixelSize: 11
              clip: true
              selectByMouse: true
              selectedTextColor: panel.selectedFg
              selectionColor: panel.accent
              onTextChanged: Root.ThemePickerState.setFilterText(text)
            }

            Text {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: 8
              visible: filterInput.text === "" && !filterInput.activeFocus
              text: Root.ThemePickerState.mode === "wallpaper" ? "FILTER WALLPAPERS" : "FILTER THEMES"
              color: panel.textMuted
              font.family: "Liberation Mono"
              font.pixelSize: 11
            }
          }

          Row {
            width: parent.width
            height: parent.height - y
            spacing: 12

            Item {
              width: Root.ThemePickerState.mode === "wallpaper" ? parent.width - previewCard.width - parent.spacing : parent.width
              height: parent.height

              ListView {
                id: themesList
                anchors.fill: parent
                clip: true
                spacing: 2
                model: Root.ThemePickerState.filteredThemes
                currentIndex: Root.ThemePickerState.selectedIndex
                visible: count > 0

                onCurrentIndexChanged: {
                  Root.ThemePickerState.selectedIndex = currentIndex
                  Root.ThemePickerState.updateSelection()
                  positionViewAtIndex(currentIndex, ListView.Contain)
                }

                delegate: Rectangle {
                  id: themeRow
                  required property int index
                  required property var model
                  readonly property bool selected: ListView.isCurrentItem

                  width: themesList.width
                  height: 22
                  color: selected ? panel.selectedBg : "transparent"

                  Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    text: themeRow.model.name
                    color: themeRow.selected ? panel.selectedFg : panel.textColor
                    font.family: "Liberation Mono"
                    font.pixelSize: 11
                    elide: Text.ElideMiddle
                  }

                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: {
                      Root.ThemePickerState.selectedIndex = themeRow.index
                      Root.ThemePickerState.updateSelection()
                    }
                    onClicked: Root.ThemePickerState.apply(themeRow.model.name, themeRow.model.path || "")
                  }
                }
              }

              Text {
                anchors.centerIn: parent
                visible: !themesList.visible
                text: "NO MATCHES"
                color: panel.textMuted
                font.family: "Liberation Mono"
                font.pixelSize: 11
                font.bold: true
              }
            }

            Rectangle {
              id: previewCard
              visible: Root.ThemePickerState.mode === "wallpaper"
              width: visible ? 250 : 0
              height: parent.height
              color: panel.surface
              border.width: 2
              border.color: panel.subtleBorder
              clip: true

              Image {
                anchors.fill: parent
                anchors.margins: 8
                source: Root.ThemePickerState.selectedPath.length > 0 ? "file://" + Root.ThemePickerState.selectedPath : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
              }

              Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: previewName.height + 16
                color: Qt.rgba(panel.panelBg.r, panel.panelBg.g, panel.panelBg.b, 0.86)

                Text {
                  id: previewName
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.leftMargin: 8
                  anchors.rightMargin: 8
                  text: Root.ThemePickerState.selectedName
                  color: panel.textColor
                  font.family: "Liberation Mono"
                  font.pixelSize: 10
                  elide: Text.ElideMiddle
                }
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
    }
  }
}
