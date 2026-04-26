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
  property string playerId: ""
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
      "player=$(playerctl -l 2>/dev/null | awk 'BEGIN{first=\"\"; playing=\"\"; mpd=\"\"} " +
      "$0 == \"mpd\" { mpd=$0 } " +
      "first == \"\" { first=$0 } " +
      "{ cmd = \"playerctl --player=\" $0 \" status 2>/dev/null\"; cmd | getline status; close(cmd); " +
      "if (tolower(status) == \"playing\" && playing == \"\") playing=$0 } " +
      "END { if (playing != \"\") print playing; else if (mpd != \"\") print mpd; else if (first != \"\") print first }'); " +
      "[ -n \"$player\" ] || exit 0; " +
      "printf '%s|' \"$player\"; " +
      "playerctl --player=\"$player\" metadata --format '{{status}}|{{playerName}}|{{artist}}|{{title}}|{{mpris:artUrl}}' 2>/dev/null || true"
    ])
  }

  function playPause() {
    controlProcess.exec(playerId ? ["playerctl", "--player=" + playerId, "play-pause"] : ["playerctl", "--player=%any", "play-pause"])
    refreshDelay.restart()
  }

  function next() {
    controlProcess.exec(playerId ? ["playerctl", "--player=" + playerId, "next"] : ["playerctl", "--player=%any", "next"])
    refreshDelay.restart()
  }

  function previous() {
    controlProcess.exec(playerId ? ["playerctl", "--player=" + playerId, "previous"] : ["playerctl", "--player=%any", "previous"])
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
      playerId = ""
      return
    }

    const parts = line.split("|")
    playerId = parts[0] || ""
    const status = (parts[1] || "").toLowerCase()
    playing = status === "playing"
    available = status !== "" && status !== "stopped"
    playerName = parts[2] || ""
    artist = parts[3] || ""
    title = parts[4] || ""
    albumArt = parts[5] || ""
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
