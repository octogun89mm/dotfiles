import QtQuick

Row {
  id: root

  property bool active: false
  readonly property int actionCount: 6

  width: implicitWidth
  spacing: 10

  VpnAction {
    width: (root.width - root.spacing * (root.actionCount - 1)) / root.actionCount
    active: root.active
  }

  IdleAction {
    width: (root.width - root.spacing * (root.actionCount - 1)) / root.actionCount
    active: root.active
  }

  SuspendAction {
    width: (root.width - root.spacing * (root.actionCount - 1)) / root.actionCount
    active: root.active
  }

  VolumeAction {
    width: (root.width - root.spacing * (root.actionCount - 1)) / root.actionCount
    active: root.active
  }

  LanguageAction {
    width: (root.width - root.spacing * (root.actionCount - 1)) / root.actionCount
    active: root.active
  }

  FruitagerAction {
    width: (root.width - root.spacing * (root.actionCount - 1)) / root.actionCount
    active: root.active
  }
}
