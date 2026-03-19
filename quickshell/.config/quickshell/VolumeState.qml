pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
  id: root

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var sinkAudio: sink ? sink.audio : null

  property int volume: volumeFromSink()
  property bool muted: sinkAudio ? sinkAudio.muted : false
  property string sinkName: sinkLabel(sink)
  property string lastOsdSinkName: sinkLabel(sink)
  property bool ready: false

  function clampVolume(value) {
    return Math.max(0, Math.min(99, Math.round(value)))
  }

  function volumeFromSink() {
    if (!sinkAudio) return 0
    return clampVolume(sinkAudio.volume * 100)
  }

  function sinkLabel(node) {
    if (!node) return ""
    return node.description || node.nickname || node.name || ""
  }

  function availableSinks() {
    const nodes = Pipewire.nodes && Pipewire.nodes.values ? Pipewire.nodes.values : []
    return nodes.filter(node => node && node.ready && node.isSink && node.audio)
  }

  function setVolume(val) {
    if (!sinkAudio) return
    sinkAudio.volume = clampVolume(val) / 100
  }

  function toggleMute() {
    if (!sinkAudio) return
    sinkAudio.muted = !sinkAudio.muted
  }

  function switchSink() {
    const sinks = availableSinks()
    if (!sink || sinks.length < 2) return

    const currentSinkId = sink.id
    const currentIndex = sinks.findIndex(node => node && node.id === currentSinkId)
    if (currentIndex === -1) {
      const fallback = sinks.find(node => node && node.id !== currentSinkId)
      if (fallback) Pipewire.preferredDefaultAudioSink = fallback
      return
    }

    Pipewire.preferredDefaultAudioSink = sinks[(currentIndex + 1) % sinks.length]
  }

  function syncFromSink() {
    const nextVolume = volumeFromSink()
    const nextMuted = sinkAudio ? sinkAudio.muted : false
    const nextSinkName = sinkLabel(sink)
    const sinkChanged = ready && nextSinkName && nextSinkName !== lastOsdSinkName

    root.volume = nextVolume
    root.muted = nextMuted
    root.sinkName = nextSinkName

    if (sinkChanged) {
      OsdState.show("󰓃", nextSinkName)
    }

    root.lastOsdSinkName = nextSinkName
  }

  onSinkChanged: syncFromSink()
  onSinkAudioChanged: syncFromSink()
  Component.onCompleted: {
    syncFromSink()
    ready = true
  }

  PwObjectTracker {
    objects: root.sink ? [root.sink] : []
  }

  Connections {
    target: root.sinkAudio

    function onMutedChanged() {
      root.muted = root.sinkAudio ? root.sinkAudio.muted : false
      if (root.ready) {
        OsdState.show(root.muted ? "󰖁" : root.volume >= 66 ? "󰕾" : root.volume >= 33 ? "󰖀" : "󰕿",
          root.muted ? "VOLUME MUTED" : "VOLUME " + root.volume + "%")
      }
    }

    function onVolumesChanged() {
      root.volume = root.volumeFromSink()
      if (root.ready && !root.muted) {
        OsdState.show(root.volume >= 66 ? "󰕾" : root.volume >= 33 ? "󰖀" : "󰕿",
          "VOLUME " + root.volume + "%")
      }
    }
  }
}
