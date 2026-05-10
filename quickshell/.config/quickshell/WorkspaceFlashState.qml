pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: root

  property string text: ""
  property string monitor: ""
  property int revision: 0
  property bool visible: false

  function show(nextText, nextMonitor) {
    text = nextText || ""
    monitor = nextMonitor || ""
    visible = true
    revision += 1
  }

  function hide() {
    visible = false
  }
}
