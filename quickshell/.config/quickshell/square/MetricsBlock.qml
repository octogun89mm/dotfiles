import QtQuick

// Compact vitals readout: "C 12% 40° M 38% G 26% 45° V 91%"
Item {
  id: root

  implicitHeight: Theme.barHeight
  implicitWidth: label.implicitWidth

  function pct(v) {
    return v >= 0 ? Math.round(v) + "%" : "--"
  }

  function deg(v) {
    return v >= 0 ? " " + Math.round(v) + "°" : ""
  }

  readonly property string vitals:
    "C " + pct(MetricsState.cpuUsage) + deg(MetricsState.cpuTemp)
    + "  M " + pct(MetricsState.memPercent)
    + "  G " + pct(MetricsState.gpuUsage) + deg(MetricsState.gpuTemp)
    + "  V " + pct(MetricsState.vramPercent)

  Text {
    id: label
    anchors.verticalCenter: parent.verticalCenter
    text: root.vitals
    color: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontMd
  }
}
