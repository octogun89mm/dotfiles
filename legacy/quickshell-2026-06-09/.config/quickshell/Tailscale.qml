import QtQuick

Rectangle {
  id: root

  property bool onlyWhenActive: false
  property color activeColor: Theme.success
  property color inactiveColor: Theme.textDim

  readonly property bool shouldShow: !onlyWhenActive || TailscaleState.connected

  visible: shouldShow
  color: "transparent"
  implicitWidth: Theme.fontSmall + 3 + Theme.padMd
  implicitHeight: Theme.chipHeight

  Text {
    id: indicator
    anchors.centerIn: parent
    text: TailscaleState.icon
    color: TailscaleState.connected ? root.activeColor : root.inactiveColor
    font.family: Theme.iconFamily
    font.pixelSize: Theme.fontSmall + 3
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.shouldShow
    onClicked: TailscaleState.toggle()
  }
}
