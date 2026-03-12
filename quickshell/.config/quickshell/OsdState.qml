pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: root

  property string icon: ""
  property string text: ""
  property int revision: 0
  property bool visible: false

  function show(nextIcon, nextText) {
    icon = nextIcon || ""
    text = nextText || ""
    visible = true
    revision += 1
  }

  function hide() {
    visible = false
  }
}
