pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property string path: (Quickshell.env("HOME") || "") + "/.cache/wallust-current-theme"
  property string name: ""

  function refresh() {
    proc.running = false
    proc.exec(["cat", root.path])
  }

  Component.onCompleted: refresh()

  Process {
    id: proc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.name = (text || "").trim()
    }
  }

  FileView {
    path: root.path
    watchChanges: true
    onFileChanged: root.refresh()
  }
}
