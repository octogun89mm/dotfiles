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
  property string mode: "theme"
  property string selectedName: ""
  property string selectedPath: ""

  readonly property string modeLabel: mode === "wallpaper" ? "WALLPAPER" : "THEME"
  readonly property string modeIcon: mode === "wallpaper" ? "󰸉" : "󰔎"
  readonly property string modePath: (Quickshell.env("HOME") || "") + "/.cache/quickshell-theme-picker-mode"

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
      const item = themesModel.get(i)
      const name = item.name || ""
      if (matchesFilter(name)) filteredModel.append({ name: name, path: item.path || "" })
    }
    selectedIndex = filteredModel.count > 0 ? 0 : -1
    updateSelection()
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
    updateSelection()
  }

  function activateSelection() {
    if (selectedIndex < 0 || selectedIndex >= filteredModel.count) return
    const item = filteredModel.get(selectedIndex)
    apply(item.name, item.path || "")
  }

  function show(monitorName) {
    if (monitorName) screenName = monitorName
    setFilterText("")
    loadItems()
    visible = true
  }

  function hide() { visible = false }

  function setMode(nextMode) {
    const cleanMode = nextMode === "wallpaper" ? "wallpaper" : "theme"
    if (mode === cleanMode) return
    mode = cleanMode
    saveModeProc.running = false
    saveModeProc.exec(["sh", "-c", "mkdir -p \"$HOME/.cache\" && printf '%s\\n' " + shellQuote(mode) + " > \"$HOME/.cache/quickshell-theme-picker-mode\""])
    setFilterText("")
    if (visible) loadItems()
  }

  function toggleMode() {
    setMode(mode === "wallpaper" ? "theme" : "wallpaper")
  }

  function updateSelection() {
    if (selectedIndex < 0 || selectedIndex >= filteredModel.count) {
      selectedName = ""
      selectedPath = ""
      return
    }

    const item = filteredModel.get(selectedIndex)
    selectedName = item.name || ""
    selectedPath = item.path || ""
  }

  function shellQuote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  function loadItems() {
    listProc.running = false
    if (mode === "wallpaper") {
      listProc.exec(["sh", "-c",
        "find \"$HOME/Pictures/Wallpapers\" -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.jxl' -o -iname '*.svg' \\) -printf '%f\\t%p\\n' 2>/dev/null | sort -f"])
    } else {
      listProc.exec(["sh", "-c",
        "{ wallust theme list | sed -r 's/\\x1B\\[[0-9;]*[mK]//g' | sed -n 's/^- //p' | sed '/^random$/d;/^list$/d'; find \"$HOME/.config/wallust/colorschemes\" -maxdepth 1 -type f -name '*.json' -printf '%f\\n' 2>/dev/null | sed 's/\\.json$//'; } | sort -u"])
    }
  }

  function apply(name, path) {
    if (!name) return
    applyProc.running = false
    if (mode === "wallpaper") {
      if (!path) return
      applyProc.exec([(Quickshell.env("HOME") || "") + "/.config/quickshell/scripts/wallpaper-apply.sh", path])
    } else {
      applyProc.exec([(Quickshell.env("HOME") || "") + "/.config/quickshell/scripts/theme-apply.sh", name])
    }
    hide()
  }

  Component.onCompleted: loadModeProc.exec(["cat", modePath])

  Process {
    id: listProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        themesModel.clear()
        const lines = (text || "").split("\n")
        for (let i = 0; i < lines.length; i++) {
          const raw = lines[i]
          const t = raw.trim()
          if (t.length === 0) continue
          if (root.mode === "wallpaper") {
            const parts = raw.split("\t")
            const name = (parts[0] || "").trim()
            const path = (parts.slice(1).join("\t") || "").trim()
            if (name.length > 0 && path.length > 0) themesModel.append({ name: name, path: path })
          } else {
            themesModel.append({ name: t, path: "" })
          }
        }
        refreshFiltered()
      }
    }
  }

  Process { id: applyProc }
  Process { id: saveModeProc }

  Process {
    id: loadModeProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        const cleanMode = (text || "").trim()
        if (cleanMode === "wallpaper" || cleanMode === "theme") root.mode = cleanMode
      }
    }
  }
}
