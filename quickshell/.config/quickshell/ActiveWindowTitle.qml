import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
  id: root

  property string windowTitle: ""
  property string windowClass: ""
  property string windowAddress: ""
  property string displayedTitle: ""
  property string displayedClass: ""
  property string previousTitle: ""
  property int maxWidth: 260

  readonly property string formattedTitle: {
    if (!windowClass && !windowTitle) return ""
    if (!windowTitle) return windowClass
    if (!windowClass) return windowTitle
    return windowClass + " → " + windowTitle
  }

  function refresh() {
    if (queryProcess.running) return
    queryProcess.exec(["hyprctl", "activewindow", "-j"])
  }

  implicitHeight: Theme.chipHeight
  implicitWidth: Math.min(maxWidth, titleText.implicitWidth + Theme.padMd * 2)
  visible: displayedTitle.length > 0 || formattedTitle.length > 0

  onFormattedTitleChanged: {
    if (formattedTitle === displayedTitle) return
    if (windowClass === displayedClass) {
      // same window, title churn (e.g. terminal app spinners) — snap, don't fade
      displayedTitle = formattedTitle
      return
    }
    swapAnim.restart()
  }

  Component.onCompleted: {
    refresh()
    displayedTitle = formattedTitle
    displayedClass = windowClass
  }

  Text {
    id: titleText
    anchors.fill: parent
    anchors.leftMargin: Theme.padMd
    anchors.rightMargin: Theme.padMd
    text: root.displayedTitle
    color: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSmall
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
    opacity: 1
  }

  SequentialAnimation {
    id: swapAnim
    NumberAnimation {
      target: titleText
      property: "opacity"
      to: 0
      duration: 120
      easing.type: Easing.InOutQuad
    }
    ScriptAction {
      script: {
        root.previousTitle = root.displayedTitle
        root.displayedTitle = root.formattedTitle
        root.displayedClass = root.windowClass
      }
    }
    NumberAnimation {
      target: titleText
      property: "opacity"
      to: 1
      duration: 120
      easing.type: Easing.InOutQuad
    }
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
          root.windowAddress = String(data.address || "")
        } catch (e) {
          root.windowTitle = ""
        }
      }
    }
  }
}
