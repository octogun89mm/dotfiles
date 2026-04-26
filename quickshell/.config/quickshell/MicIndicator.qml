import QtQuick

Rectangle {
  id: root

  property bool onlyWhenActive: true
  property color activeColor: Theme.critical
  property color inactiveColor: Theme.textDim

  visible: !onlyWhenActive || MicState.active
  color: "transparent"
  implicitWidth: row.implicitWidth + Theme.padMd + Theme.stripe
  implicitHeight: Theme.chipHeight

  Rectangle {
    visible: MicState.active
    anchors {
      left: parent.left
      top: parent.top
      bottom: parent.bottom
    }
    width: Theme.stripe
    color: root.activeColor
  }

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: Theme.stripe + Theme.padSm
    spacing: Theme.padSm

    Text {
      visible: MicState.active
      anchors.verticalCenter: parent.verticalCenter
      text: "MIC ON LIVE"
      color: root.activeColor
      font.family: "Iosevka Heavy"
      font.pixelSize: Theme.fontSmall
    }

    Text {
      id: indicator
      anchors.verticalCenter: parent.verticalCenter
      text: MicState.active ? "󰍬" : "󰍭"
      color: MicState.active ? root.activeColor : root.inactiveColor
      font.family: Theme.iconFamily
      font.pixelSize: Theme.fontSmall + 3
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
  }
}
