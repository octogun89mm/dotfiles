import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
  id: root

  property string activeAddress: ""
  property var windows: []
  property int maxWidth: 600
  property int chipWidth: 180
  property bool collapsed: false
  readonly property int handleWidth: 14

  readonly property var visibleWindows: {
    const out = []
    for (let i = 0; i < windows.length; i++) {
      const w = windows[i]
      if (!w) continue
      if (!w.class && !w.title) continue
      if (w.workspace < 0) continue
      out.push(w)
    }
    out.sort((a, b) => {
      const aActive = a.address === activeAddress ? 0 : 1
      const bActive = b.address === activeAddress ? 0 : 1
      if (aActive !== bActive) return aActive - bActive
      return 0
    })
    return out
  }

  function refresh() {
    if (clientsProcess.running) return
    clientsProcess.exec(["hyprctl", "clients", "-j"])
    activeProcess.exec(["hyprctl", "activewindow", "-j"])
  }

  function focusWindow(address) {
    if (!address) return
    focusProcess.exec(["hyprctl", "dispatch", "focuswindow", "address:" + address])
  }

  function formatLabel(w) {
    return w.title || w.class || ""
  }

  function iconFor(w) {
    if (!w.class) return ""
    return Quickshell.iconPath(w.class.toLowerCase(), true)
        || Quickshell.iconPath(w.class, true)
        || ""
  }

  implicitHeight: Theme.chipHeight
  implicitWidth: collapsed
      ? handleWidth * 2 + Theme.padXs * 2
      : Math.min(row.implicitWidth + handleWidth * 2 + Theme.padXs * 2, maxWidth)
  visible: visibleWindows.length > 0

  clip: true

  Behavior on implicitWidth {
    NumberAnimation { duration: 220; easing.type: Easing.InOutCubic }
  }

  Item {
    id: leftHandle
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: root.handleWidth
    height: Theme.chipHeight
    Text {
      anchors.centerIn: parent
      text: root.collapsed ? "›" : "‹"
      color: leftHandleArea.containsMouse ? Theme.text : Theme.textDim
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontSmall + 4
      font.bold: true
      Behavior on color { ColorAnimation { duration: 150 } }
    }
    MouseArea {
      id: leftHandleArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.collapsed = !root.collapsed
    }
  }

  Item {
    id: rightHandle
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: root.handleWidth
    height: Theme.chipHeight
    Text {
      anchors.centerIn: parent
      text: root.collapsed ? "‹" : "›"
      color: rightHandleArea.containsMouse ? Theme.text : Theme.textDim
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontSmall + 4
      font.bold: true
      Behavior on color { ColorAnimation { duration: 150 } }
    }
    MouseArea {
      id: rightHandleArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.collapsed = !root.collapsed
    }
  }

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: leftHandle.right
    anchors.right: rightHandle.left
    anchors.leftMargin: Theme.padXs
    anchors.rightMargin: Theme.padXs
    opacity: root.collapsed ? 0 : 1
    visible: opacity > 0
    spacing: Theme.padMd

    Behavior on opacity {
      NumberAnimation { duration: 180; easing.type: Easing.InOutCubic }
    }

    Repeater {
      model: root.visibleWindows

      Item {
        id: chip
        required property var modelData
        required property int index
        implicitHeight: Theme.chipHeight
        implicitWidth: root.chipWidth

        readonly property bool isActive: chip.modelData.address === root.activeAddress

        Rectangle {
          anchors.fill: parent
          color: hover.containsMouse ? Theme.surface : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.5)
          border.color: chip.isActive ? Theme.accent : Theme.border
          border.width: 1
          radius: 0
          clip: true

          Rectangle {
            id: wsBadge
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            visible: chip.modelData.workspace > 0
            width: wsLabel.implicitWidth + Theme.padSm * 2
            color: chip.isActive ? Theme.accent : Theme.border
            radius: 0

            Text {
              id: wsLabel
              anchors.centerIn: parent
              text: chip.modelData.workspace
              color: chip.isActive ? Theme.bg : Theme.text
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontCaption
              font.weight: Font.Black
            }
          }
        }

        Row {
          id: chipContent
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          anchors.leftMargin: (wsBadge.visible ? wsBadge.width : 0) + Theme.padSm
          anchors.rightMargin: Theme.padSm
          spacing: Theme.padXs

          Image {
            id: chipIcon
            anchors.verticalCenter: parent.verticalCenter
            source: root.iconFor(chip.modelData)
            visible: source != ""
            sourceSize.width: Theme.fontSmall + 4
            sourceSize.height: Theme.fontSmall + 4
            width: visible ? Theme.fontSmall + 4 : 0
            height: Theme.fontSmall + 4
            fillMode: Image.PreserveAspectFit
            smooth: true
          }

          Text {
            id: chipText
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - (chipIcon.visible ? (chipIcon.width + parent.spacing) : 0)
            text: root.formatLabel(chip.modelData)
            color: chip.isActive ? Theme.text : (hover.containsMouse ? Theme.text : Theme.textDim)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            font.bold: chip.isActive
            elide: Text.ElideRight
          }
        }

        MouseArea {
          id: hover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.focusWindow(chip.modelData.address)
        }
      }
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      const name = event.name
      if (name === "openwindow"
          || name === "closewindow"
          || name === "movewindow"
          || name === "movewindowv2"
          || name === "windowtitle"
          || name === "windowtitlev2"
          || name === "activewindow"
          || name === "activewindowv2") {
        root.refresh()
      }
    }
  }

  Component.onCompleted: refresh()

  Process {
    id: clientsProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (!text || !text.trim()) {
          root.windows = []
          return
        }
        try {
          const data = JSON.parse(text)
          if (Array.isArray(data)) {
            root.windows = data.map(c => ({
              address: String(c.address || ""),
              class: String(c.class || ""),
              title: String(c.title || ""),
              workspace: c.workspace && typeof c.workspace.id === "number" ? c.workspace.id : 0
            }))
          } else {
            root.windows = []
          }
        } catch (e) {
          root.windows = []
        }
      }
    }
  }

  Process {
    id: focusProcess
  }

  Process {
    id: activeProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (!text || !text.trim()) {
          root.activeAddress = ""
          return
        }
        try {
          const data = JSON.parse(text)
          root.activeAddress = String(data.address || "")
        } catch (e) {
          root.activeAddress = ""
        }
      }
    }
  }
}
