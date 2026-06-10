import QtQuick

// Compact "C 12% M 38%" metric readout.
Item {
  id: root

  implicitHeight: Theme.barHeight
  implicitWidth: label.implicitWidth

  readonly property string cpuText: MetricsState.cpuUsage >= 0
    ? Math.round(MetricsState.cpuUsage) + "%"
    : "--"
  readonly property string memText: MetricsState.memPercent >= 0
    ? Math.round(MetricsState.memPercent) + "%"
    : "--"

  Text {
    id: label
    anchors.verticalCenter: parent.verticalCenter
    text: "C " + root.cpuText + " M " + root.memText
    color: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontMd
  }
}
