pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: root

  readonly property var styles: [
    "spectrogram",
    "bars",
    "wave",
    "dots",
    "mirror",
    "circles",
    "spikes",
    "stairs",
    "triangle",
    "glow",
    "ribbon",
    "equalizer",
    "scope",
    "off"
  ]
  property int index: 0
  readonly property string current: styles[index]
  property bool offLabelVisible: false
  property bool offLabelOn: false

  function setIndex(nextIndex) {
    index = (nextIndex + styles.length) % styles.length
    if (current === "off") showOffLabel()
  }

  function next() { setIndex(index + 1) }
  function prev() { setIndex(index - 1) }

  function showOffLabel() {
    offHoldTimer.stop()
    offHideTimer.stop()
    offFadeInTimer.stop()
    offLabelOn = false
    offLabelVisible = true
    offFadeInTimer.restart()
  }

  Timer {
    id: offFadeInTimer
    interval: 1
    repeat: false
    onTriggered: {
      root.offLabelOn = true
      offHoldTimer.restart()
    }
  }

  Timer {
    id: offHoldTimer
    interval: 650
    repeat: false
    onTriggered: {
      root.offLabelOn = false
      offHideTimer.restart()
    }
  }

  Timer {
    id: offHideTimer
    interval: 260
    repeat: false
    onTriggered: root.offLabelVisible = false
  }
}
