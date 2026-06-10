import QtQuick

// A hard rectangular module block with optional accent stripe and divider.
// Drop content inside via default property (children).
Rectangle {
  id: root

  default property alias content: contentItem.children

  // Accent stripe on the top edge — used to mark "important/active" blocks.
  property bool accentTop: false
  property color accentColor: Theme.accent

  // Hairline divider on one side (separates this block from its neighbour).
  property bool dividerRight: false
  property bool dividerLeft: false

  // When true, the block collapses to zero width and hides — used for
  // modules that should disappear entirely when not relevant (e.g. mic).
  property bool collapsed: false

  color: Theme.bg
  radius: 0
  implicitHeight: Theme.barHeight
  implicitWidth: collapsed ? 0 : (contentItem.implicitWidth + Theme.padMd * 2)
  visible: !collapsed

  Item {
    id: contentItem
    anchors.fill: parent
    anchors.leftMargin: Theme.padMd
    anchors.rightMargin: Theme.padMd
    implicitWidth: childrenRect.width
  }

  Rectangle {
    visible: root.accentTop
    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
    }
    height: Theme.stripe
    color: root.accentColor
  }

  Rectangle {
    visible: root.dividerRight
    anchors {
      top: parent.top
      bottom: parent.bottom
      right: parent.right
    }
    width: Theme.hairline
    color: Theme.border
  }

  Rectangle {
    visible: root.dividerLeft
    anchors {
      top: parent.top
      bottom: parent.bottom
      left: parent.left
    }
    width: Theme.hairline
    color: Theme.border
  }
}
