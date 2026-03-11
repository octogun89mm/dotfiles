pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property int volume: 0
  property bool muted: false
  property string sinkName: ""
  property bool settling: false

  function setVolume(val) {
    root.volume = val
    root.settling = true
    scrollDebounce.restart()
    settleTimer.restart()
  }

  function toggleMute() {
    root.muted = !root.muted
    root.settling = true
    settleTimer.restart()
    muteProcess.running = true
  }

  function switchSink() {
    switchSinkProcess.running = true
  }

  Timer {
    id: scrollDebounce
    interval: 80
    onTriggered: {
      setVolumeProcess.command = ["/home/juju/.dotfiles/quickshell/.config/quickshell/scripts/volume.sh", "set", root.volume.toString()]
      setVolumeProcess.running = true
    }
  }

  Timer {
    id: settleTimer
    interval: 500
    onTriggered: root.settling = false
  }

  Process {
    command: ["/home/juju/.dotfiles/quickshell/.config/quickshell/scripts/volume-monitor.sh"]
    running: true

    stdout: SplitParser {
      splitMarker: "\n"
      onRead: function(data) {
        if (!data || !data.trim()) return
        if (root.settling) return
        const parsed = JSON.parse(data)
        const vol = parsed.volume
        if (typeof vol === "number") root.volume = Math.min(vol, 99)
        root.muted = !!parsed.muted
        if (parsed.sink) root.sinkName = parsed.sink
      }
    }
  }

  Process {
    id: setVolumeProcess
    running: false
  }

  Process {
    id: muteProcess
    command: ["/home/juju/.dotfiles/quickshell/.config/quickshell/scripts/volume.sh", "mute"]
    running: false
  }

  Process {
    id: switchSinkProcess
    command: ["/home/juju/.dotfiles/quickshell/.config/quickshell/scripts/volume.sh", "switch-sink"]
    running: false
  }
}
