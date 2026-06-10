pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  function resolvedPath(path) {
    const resolved = Qt.resolvedUrl(path).toString()
    return resolved.indexOf("file://") === 0 ? resolved.slice(7) : resolved
  }

  readonly property string scriptPath: resolvedPath("../scripts/hypr_binds_json.py")

  property bool visible: false
  property string screenName: ""
  property var binds: []
  property var modifierModes: []
  property var submaps: []
  property string selectedModifierMode: "SUPER"
  property string selectedSubmap: "global"
  property bool loading: false
  property string errorText: ""
  readonly property var activeBinds: binds.filter(function(bind) {
    return bind.modifierMode === selectedModifierMode && bind.submap === selectedSubmap
  })
  readonly property var keyBindMap: {
    const map = {}

    for (let i = 0; i < activeBinds.length; i++) {
      const bind = activeBinds[i]
      const key = bind.normalizedKey
      if (!key || bind.mouse) continue

      if (!map[key]) map[key] = []
      map[key].push(bind)
    }

    return map
  }

  function show(monitorName) {
    if (monitorName) {
      screenName = monitorName
    }

    visible = true
    refresh()
  }

  function hide() {
    visible = false
  }

  function toggle(monitorName) {
    if (visible && (!monitorName || screenName === monitorName)) {
      hide()
      return
    }

    show(monitorName)
  }

  function refresh() {
    loading = true
    errorText = ""
    bindsProcess.exec(["python3", scriptPath])
  }

  function ensureSelections() {
    if (modifierModes.indexOf(selectedModifierMode) === -1) {
      selectedModifierMode = modifierModes.indexOf("SUPER") >= 0
        ? "SUPER"
        : (modifierModes.length > 0 ? modifierModes[0] : "PLAIN")
    }

    if (submaps.indexOf(selectedSubmap) === -1) {
      selectedSubmap = submaps.indexOf("global") >= 0
        ? "global"
        : (submaps.length > 0 ? submaps[0] : "global")
    }
  }

  function setModifierMode(mode) {
    selectedModifierMode = mode
  }

  function setSubmap(submap) {
    selectedSubmap = submap
  }

  function filteredBinds() {
    return activeBinds
  }

  function selectedModifiers() {
    return selectedModifierMode === "PLAIN" ? [] : selectedModifierMode.split("+")
  }

  function modifierActive(name) {
    return selectedModifiers().indexOf(name) >= 0
  }

  function keyBinds(keyId) {
    return keyBindMap[keyId] || []
  }

  function keyDisplayBind(keyId) {
    const matches = keyBinds(keyId)
    if (matches.length === 0) return null

    return {
      desc: matches.slice(0, 3).map(function(bind) { return bind.desc }).join("\n"),
      category: matches[0].category,
      combo: matches[0].combo,
      count: matches.length,
    }
  }

  function mouseBinds() {
    return activeBinds.filter(function(bind) {
      return bind.mouse
    })
  }

  function unplacedBinds() {
    return activeBinds.filter(function(bind) {
      return !bind.mouse && (!bind.normalizedKey || !keyboardKeys[bind.normalizedKey])
    })
  }

  readonly property var keyboardKeys: ({
    "ESC": true,
    "F1": true,
    "F2": true,
    "F3": true,
    "F4": true,
    "F5": true,
    "F6": true,
    "F7": true,
    "F8": true,
    "F9": true,
    "F10": true,
    "F11": true,
    "F12": true,
    "PRINT": true,
    "INSERT": true,
    "DELETE": true,
    "HOME": true,
    "END": true,
    "PAGEUP": true,
    "PAGEDOWN": true,
    "GRAVE": true,
    "1": true,
    "2": true,
    "3": true,
    "4": true,
    "5": true,
    "6": true,
    "7": true,
    "8": true,
    "9": true,
    "0": true,
    "MINUS": true,
    "EQUAL": true,
    "BACKSPACE": true,
    "TAB": true,
    "Q": true,
    "W": true,
    "E": true,
    "R": true,
    "T": true,
    "Y": true,
    "U": true,
    "I": true,
    "O": true,
    "P": true,
    "BRACKETLEFT": true,
    "BRACKETRIGHT": true,
    "BACKSLASH": true,
    "CAPSLOCK": true,
    "A": true,
    "S": true,
    "D": true,
    "F": true,
    "G": true,
    "H": true,
    "J": true,
    "K": true,
    "L": true,
    "SEMICOLON": true,
    "APOSTROPHE": true,
    "ENTER": true,
    "SHIFT": true,
    "SHIFT_R": true,
    "Z": true,
    "X": true,
    "C": true,
    "V": true,
    "B": true,
    "N": true,
    "M": true,
    "COMMA": true,
    "PERIOD": true,
    "SLASH": true,
    "CTRL": true,
    "SUPER": true,
    "ALT": true,
    "SPACE": true,
    "ALT_R": true,
    "SUPER_R": true,
    "LEFT": true,
    "DOWN": true,
    "UP": true,
    "RIGHT": true
  })

  function parsePayload(text) {
    loading = false

    if (!text || !text.trim()) {
      errorText = "No binding data returned."
      return
    }

    try {
      const data = JSON.parse(text)

      if (data.error) {
        errorText = data.error
        return
      }

      binds = data.binds || []
      modifierModes = data.modifierModes || []
      submaps = data.submaps || []
      ensureSelections()
    } catch (error) {
      errorText = "Failed to parse Hyprland binds."
      console.warn("KeybindState: parse failure", error)
    }
  }

  Process {
    id: bindsProcess

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parsePayload(text)
    }

    onExited: function(exitCode) {
      if (exitCode !== 0 && !root.errorText) {
        root.loading = false
        root.errorText = "hyprctl binds failed."
      }
    }
  }
}
