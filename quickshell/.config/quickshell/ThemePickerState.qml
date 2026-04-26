pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool visible: false
  property string screenName: ""
  property string filterText: ""
  property int selectedIndex: 0

  readonly property alias themes: themesModel
  readonly property alias filteredThemes: filteredModel

  ListModel { id: themesModel }
  ListModel { id: filteredModel }

  function matchesFilter(name) {
    if (!filterText) return true
    return name.toLowerCase().indexOf(filterText.toLowerCase()) >= 0
  }

  function refreshFiltered() {
    filteredModel.clear()
    for (let i = 0; i < themesModel.count; i++) {
      const name = themesModel.get(i).name
      if (matchesFilter(name)) filteredModel.append({ name: name })
    }
    selectedIndex = filteredModel.count > 0 ? 0 : -1
  }

  function setFilterText(text) {
    filterText = text || ""
    refreshFiltered()
  }

  function moveSelection(delta) {
    if (filteredModel.count === 0) { selectedIndex = -1; return }
    let next = selectedIndex + delta
    if (next < 0) next = 0
    if (next >= filteredModel.count) next = filteredModel.count - 1
    selectedIndex = next
  }

  function activateSelection() {
    if (selectedIndex < 0 || selectedIndex >= filteredModel.count) return
    apply(filteredModel.get(selectedIndex).name)
  }

  function show(monitorName) {
    if (monitorName) screenName = monitorName
    setFilterText("")
    if (themesModel.count === 0) loadThemes()
    visible = true
  }

  function hide() { visible = false }

  function loadThemes() {
    listProc.running = false
    listProc.exec(["sh", "-c",
      "wallust theme list | sed -r 's/\\x1B\\[[0-9;]*[mK]//g' | sed -n 's/^- //p' | sed '/^random$/d;/^list$/d' | sort -u"])
  }

  function apply(name) {
    if (!name) return
    applyProc.running = false
    applyProc.exec(["sh", "-c",
      "n=\"$1\"; if [ -f \"$HOME/.config/wallust/colorschemes/$n.json\" ]; then wallust cs \"$n\"; else wallust theme \"$n\"; fi; printf '%s\\n' \"$n\" > \"$HOME/.cache/wallust-current-theme\"; setsid -f \"$HOME/.config/quickshell/scripts/restart.sh\" >/dev/null 2>&1 || true",
      "_", name])
    hide()
  }

  Process {
    id: listProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        themesModel.clear()
        const lines = (text || "").split("\n")
        for (let i = 0; i < lines.length; i++) {
          const t = lines[i].trim()
          if (t.length > 0) themesModel.append({ name: t })
        }
        refreshFiltered()
      }
    }
  }

  Process { id: applyProc }
}
