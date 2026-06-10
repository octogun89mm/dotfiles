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
  property int missedRefreshes: 0

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
      "player=$(playerctl -l 2>/dev/null | awk 'BEGIN{first=\"\"; playing=\"\"; available=\"\"} " +
      "first == \"\" { first=$0 } " +
      "{ cmd = \"playerctl --player=\" $0 \" status 2>/dev/null\"; cmd | getline status; close(cmd); " +
      "status = tolower(status); " +
      "if (status == \"playing\" && playing == \"\") playing=$0; " +
      "if (status != \"\" && status != \"stopped\" && available == \"\") available=$0 } " +
      "END { if (playing != \"\") print playing; else if (available != \"\") print available; else if (first != \"\") print first }'); " +
      "[ -n \"$player\" ] || exit 0; " +
      "status=$(playerctl --player=\"$player\" status 2>/dev/null || true); " +
      "printf '%s|%s|' \"$player\" \"$status\"; " +
      "playerctl --player=\"$player\" metadata --format '{{playerName}}|{{artist}}|{{title}}|{{mpris:artUrl}}' 2>/dev/null || true"
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

  function clear() {
    available = false
    playing = false
    title = ""
    artist = ""
    albumArt = ""
    playerName = ""
    playerId = ""
  }

  function parseStatus(text) {
    const line = text ? text.trim().split("\n")[0] : ""
    if (!line) {
      missedRefreshes++
      playing = false
      if (missedRefreshes >= 3)
        clear()
      return
    }

    missedRefreshes = 0
    const parts = line.split("|")
    const nextPlayerId = parts[0] || ""
    const samePlayer = nextPlayerId !== "" && nextPlayerId === playerId
    const status = (parts[1] || "").toLowerCase()
    const nextPlayerName = parts[2] || ""
    const nextArtist = parts[3] || ""
    const nextTitle = parts[4] || ""
    const nextAlbumArt = parts[5] || ""

    playing = status === "playing"
    available = status !== "" && status !== "stopped"

    if (!available) {
      clear()
      return
    }

    playerId = nextPlayerId
    playerName = nextPlayerName || (samePlayer ? playerName : "")
    artist = nextArtist || (samePlayer ? artist : "")
    title = nextTitle || (samePlayer ? title : "")
    albumArt = nextAlbumArt || (samePlayer ? albumArt : "")
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
