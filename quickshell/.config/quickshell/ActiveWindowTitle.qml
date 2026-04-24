import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
  id: root

  property string windowTitle: ""
  property string windowClass: ""
  property int maxWidth: 260

  function refresh() {
    if (queryProcess.running) return
    queryProcess.exec(["hyprctl", "activewindow", "-j"])
  }

  implicitHeight: Theme.chipHeight
  implicitWidth: Math.min(maxWidth, titleText.implicitWidth + Theme.padMd * 2)
  visible: windowTitle.length > 0

  Text {
    id: titleText
    anchors.fill: parent
    anchors.leftMargin: Theme.padMd
    anchors.rightMargin: Theme.padMd
    text: root.windowTitle
    color: Theme.textMuted
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSmall
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      const name = event.name
      if (name === "activewindow"
          || name === "activewindowv2"
          || name === "closewindow"
          || name === "windowtitle"
          || name === "windowtitlev2") {
        root.refresh()
      }
    }
  }

  Component.onCompleted: refresh()

  Process {
    id: queryProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (!text || !text.trim()) {
          root.windowTitle = ""
          return
        }
        try {
          const data = JSON.parse(text)
          root.windowTitle = String(data.title || "")
          root.windowClass = String(data.class || "")
        } catch (e) {
          root.windowTitle = ""
        }
      }
    }
  }
}
