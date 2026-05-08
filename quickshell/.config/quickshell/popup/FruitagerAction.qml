import QtQuick
import Quickshell
import Quickshell.Io
import ".." as Root

ActionCard {
  id: root

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string applyScript: home + "/.config/quickshell/scripts/theme-apply.sh"
  property bool active: false

  title: "FRUIT"
  icon: "󰌪"
  value: Root.ThemeNameState.name === "fruitager-light" ? "ON" : "LIGHT"
  highlighted: Root.ThemeNameState.name === "fruitager-light"

  onClicked: applyProc.exec([applyScript, "fruitager-light"])

  Process { id: applyProc }
}
