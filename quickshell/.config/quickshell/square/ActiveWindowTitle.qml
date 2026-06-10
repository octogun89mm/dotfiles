import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Active window title — textMuted, elided, max ~40ch.
Item {
  id: root

  property string windowTitle: ""
  property string windowClass: ""
  readonly property int maxChars: 40

  readonly property string formattedTitle: {
    if (!windowClass && !windowTitle) return ""
    if (!windowTitle) return windowClass
    return windowTitle
  }

  function refresh() {
    if (queryProcess.running) return
    queryProcess.exec(["hyprctl", "activewindow", "-j"])
  }

  implicitHeight: Theme.barHeight
  implicitWidth: titleText.implicitWidth
  visible: formattedTitle.length > 0

  Component.onCompleted: refresh()

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

  Text {
    id: titleText
    anchors.verticalCenter: parent.verticalCenter
    text: root.formattedTitle.length > root.maxChars
      ? root.formattedTitle.substring(0, root.maxChars - 1) + "…"
      : root.formattedTitle
    color: Theme.textMuted
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontMd
    elide: Text.ElideRight
  }

  Process {
    id: queryProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (!text || !text.trim()) {
          root.windowTitle = ""
          root.windowClass = ""
          return
        }
        try {
          const data = JSON.parse(text)
          root.windowTitle = String(data.title || "")
          root.windowClass = String(data.class || "")
        } catch (e) {
          root.windowTitle = ""
          root.windowClass = ""
        }
      }
    }
  }
}
