import QtQuick

Row {
  id: root

  property bool active: false

  width: implicitWidth
  spacing: 10

  VpnAction {
    width: (root.width - root.spacing * 3) / 4
    active: root.active
  }

  IdleAction {
    width: (root.width - root.spacing * 3) / 4
    active: root.active
  }

  VolumeAction {
    width: (root.width - root.spacing * 3) / 4
    active: root.active
  }

  LanguageAction {
    width: (root.width - root.spacing * 3) / 4
    active: root.active
  }
}
