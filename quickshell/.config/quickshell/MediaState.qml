pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property string title: ""
  property string artist: ""
  property string albumArt: ""
  property bool playing: false
  property string playerName: ""
  property bool available: false

  readonly property string displayText: {
    if (!available) return "NO MEDIA"
    if (artist && title) return artist + " - " + title
    return title || artist || playerName || "NO MEDIA"
  }

  function refresh() {
    statusProcess.exec([
      "/bin/sh",
      "-c",
      "command -v playerctl >/dev/null 2>&1 || exit 0; " +
      "player=$(playerctl -l 2>/dev/null | awk 'BEGIN{first=\"\"; playing=\"\"; chosen=\"\"} " +
      "$0 == \"mpd\" { chosen=$0; print chosen; exit } " +
      "first == \"\" { first=$0 } " +
      "{ cmd = \"playerctl --player=\" $0 \" status 2>/dev/null\"; cmd | getline status; close(cmd); " +
      "if (tolower(status) == \"playing\" && playing == \"\") playing=$0 } " +
      "END { if (chosen != \"\") exit; if (playing != \"\") print playing; else if (first != \"\") print first }'); " +
      "[ -n \"$player\" ] || exit 0; " +
      "playerctl --player=\"$player\" metadata --format '{{status}}|{{playerName}}|{{artist}}|{{title}}|{{mpris:artUrl}}' 2>/dev/null || true"
    ])
  }

  function playPause() {
    controlProcess.exec(["/bin/sh", "-c", "command -v playerctl >/dev/null 2>&1 || exit 0; playerctl --player=mpd,%any play-pause 2>/dev/null || true"])
    refreshDelay.restart()
  }

  function next() {
    controlProcess.exec(["/bin/sh", "-c", "command -v playerctl >/dev/null 2>&1 || exit 0; playerctl --player=mpd,%any next 2>/dev/null || true"])
    refreshDelay.restart()
  }

  function previous() {
    controlProcess.exec(["/bin/sh", "-c", "command -v playerctl >/dev/null 2>&1 || exit 0; playerctl --player=mpd,%any previous 2>/dev/null || true"])
    refreshDelay.restart()
  }

  function parseStatus(text) {
    const line = text ? text.trim().split("\n")[0] : ""
    if (!line) {
      available = false
      playing = false
      title = ""
      artist = ""
      albumArt = ""
      playerName = ""
      return
    }

    const parts = line.split("|")
    const status = (parts[0] || "").toLowerCase()
    playing = status === "playing"
    available = status !== "stopped"
    playerName = parts[1] || ""
    artist = parts[2] || ""
    title = parts[3] || ""
    albumArt = parts[4] || ""
  }

  Component.onCompleted: refresh()

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Timer {
    id: refreshDelay
    interval: 150
    repeat: false
    onTriggered: root.refresh()
  }

  Process {
    id: statusProcess

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseStatus(text)
    }
  }

  Process {
    id: controlProcess
  }
}
