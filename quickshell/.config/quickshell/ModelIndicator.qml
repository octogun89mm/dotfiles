import QtQuick
import QtQuick.Controls as Controls

Rectangle {
  id: root

  visible: ModelState.loaded
  color: "transparent"
  implicitWidth: indicator.implicitWidth + Theme.padMd
  implicitHeight: Theme.chipHeight

  Controls.ToolTip.visible: hover.containsMouse && ModelState.tooltip !== ""
  Controls.ToolTip.text: ModelState.tooltip
  Controls.ToolTip.delay: 350

  Text {
    id: indicator
    anchors.centerIn: parent
    text: ModelState.icon
    color: Theme.accent
    font.family: Theme.iconFamily
    font.pixelSize: Theme.fontSmall + 3
  }

  MouseArea {
    id: hover
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
  }
}
