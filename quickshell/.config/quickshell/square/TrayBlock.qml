import QtQuick
import Quickshell.Services.SystemTray

// System tray icons, shown in a row.
Row {
  id: root

  spacing: Theme.padSm
  height: Theme.barHeight

  Repeater {
    model: SystemTray.items

    TrayItem {
      required property var modelData
      anchors.verticalCenter: parent.verticalCenter
      item: modelData
      iconSize: 16
    }
  }
}
