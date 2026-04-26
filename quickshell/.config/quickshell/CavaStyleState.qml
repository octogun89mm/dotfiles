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
    "scope"
  ]
  property int index: 0
  readonly property string current: styles[index]

  function next() { index = (index + 1) % styles.length }
  function prev() { index = (index - 1 + styles.length) % styles.length }
}
