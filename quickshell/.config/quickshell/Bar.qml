import QtQuick
import Quickshell

Scope {
  readonly property string selectedMode: {
    const value = (Quickshell.env("QUICKSHELL_BAR_MODE") || "simple").trim().toLowerCase()
    return value === "floaty" ? "floaty" : "simple"
  }

  Loader {
    active: true
    sourceComponent: selectedMode === "floaty" ? floatyBar : simpleBar
  }

  Component {
    id: floatyBar

    FloatyBar {}
  }

  Component {
    id: simpleBar

    SimpleBar {}
  }
}
