pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool visible: false
  property string screenName: ""
  property string text: ""
  property int selectedIndex: 0

  readonly property alias engines: enginesModel

  ListModel {
    id: enginesModel
    ListElement { name: "Kokoro";        subtitle: "fast local, default";              flags: "" }
    ListElement { name: "Orpheus";       subtitle: "expressive, <laugh> <sigh>";       flags: "-x" }
    ListElement { name: "Gemini";        subtitle: "remote, OpenRouter";               flags: "-r" }
    ListElement { name: "Gemini Quebec"; subtitle: "remote, Quebec-French style";      flags: "-r|-q" }
    ListElement { name: "Gemini Movie";  subtitle: "remote, trailer-narrator (Charon)"; flags: "-m" }
  }

  function show(textArg, monitorName) {
    text = textArg || ""
    if (monitorName) screenName = monitorName
    else if (Quickshell.screens.length > 0) screenName = Quickshell.screens[0].name
    selectedIndex = 0
    visible = true
  }

  function hide() { visible = false }

  function moveSelection(delta) {
    if (enginesModel.count === 0) return
    let next = selectedIndex + delta
    if (next < 0) next = 0
    if (next >= enginesModel.count) next = enginesModel.count - 1
    selectedIndex = next
  }

  function activateSelection() {
    if (selectedIndex < 0 || selectedIndex >= enginesModel.count) return
    const item = enginesModel.get(selectedIndex)
    apply(item.flags)
  }

  function apply(flags) {
    if (!text || text.length === 0) { hide(); return }
    const args = ["speak"]
    if (flags && flags.length > 0) {
      const parts = String(flags).split("|")
      for (let i = 0; i < parts.length; i++) {
        if (parts[i].length > 0) args.push(parts[i])
      }
    }
    args.push(text)
    speakProc.running = false
    speakProc.command = args
    speakProc.running = true
    hide()
  }

  Process { id: speakProc }
}
