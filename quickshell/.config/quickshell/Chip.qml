import QtQuick

// Small bar/overlay cell. Transparent bg by default. Optional 2px left accent
// stripe, optional hover bg, optional click handler. Sharp corners.
Rectangle {
  id: root

  property string label: ""
  property string icon: ""
  property color accentColor: Theme.accent
  property bool stripe: false
  property bool hoverable: false
  property bool bold: false
  property int fontSize: Theme.fontSmall
  property color fgColor: Theme.text
  property color bgColor: "transparent"
  property color hoverBg: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
  property int horizontalPadding: Theme.padMd
  property int iconGap: Theme.padSm

  signal clicked()

  implicitHeight: Theme.chipHeight
  implicitWidth: content.implicitWidth + horizontalPadding * 2 + (stripe ? Theme.stripe : 0)
  color: mouseArea.containsMouse && hoverable ? hoverBg : bgColor
  border.width: 0

  // Left accent stripe
  Rectangle {
    visible: root.stripe
    anchors {
      left: parent.left
      top: parent.top
      bottom: parent.bottom
    }
    width: Theme.stripe
    color: root.accentColor
  }

  Row {
    id: content
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: root.horizontalPadding + (root.stripe ? Theme.stripe : 0)
    spacing: root.iconGap

    Text {
      visible: root.icon.length > 0
      anchors.verticalCenter: parent.verticalCenter
      text: root.icon
      font.family: Theme.iconFamily
      font.pixelSize: root.fontSize + 2
      color: root.fgColor
    }

    Text {
      visible: root.label.length > 0
      anchors.verticalCenter: parent.verticalCenter
      text: root.label
      font.family: Theme.fontFamily
      font.pixelSize: root.fontSize
      font.bold: root.bold
      color: root.fgColor
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: root.hoverable
    acceptedButtons: Qt.LeftButton
    onClicked: root.clicked()
  }
}
