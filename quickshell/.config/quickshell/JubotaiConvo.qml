import QtQuick

Rectangle {
  id: root

  property bool onlyWhenActive: false
  property color onColor: Theme.success
  property color partialColor: Theme.warning
  property color offColor: Theme.textDim

  visible: !onlyWhenActive || JubotaiConvoState.on
  color: "transparent"
  implicitWidth: indicator.implicitWidth + Theme.padMd
  implicitHeight: Theme.chipHeight

  Text {
    id: indicator
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: Theme.padSm
    text: JubotaiConvoState.icon
    color: JubotaiConvoState.on
           ? root.onColor
           : (JubotaiConvoState.partial ? root.partialColor : root.offColor)
    font.family: Theme.iconFamily
    font.pixelSize: Theme.fontSmall + 3
  }

  MouseArea {
    anchors.fill: parent
    onClicked: JubotaiConvoState.toggle()
  }
}
