import QtQuick

// Container surface — 1px hairline border, optional 2px top accent stripe.
// Sharp corners. Use `contentItem` as the default child slot.
Rectangle {
  id: root

  default property alias contentItem: contentHolder.data

  property color topStripeColor: "transparent"
  property bool topStripe: false
  property int padding: Theme.padLg
  property color borderColor: Theme.border
  property color surfaceColor: Theme.surface

  color: surfaceColor
  border.width: Theme.hairline
  border.color: borderColor

  Rectangle {
    visible: root.topStripe
    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
    }
    height: Theme.stripe
    color: root.topStripeColor
  }

  Item {
    id: contentHolder
    anchors.fill: parent
    anchors.margins: root.padding
    anchors.topMargin: root.padding + (root.topStripe ? Theme.stripe : 0)
  }
}
