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
  property bool ready: false

  function clampVolume(value) {
    return Math.max(0, Math.min(100, Math.round(value)))
  }

  function volumeFromSink() {
    if (!sinkAudio) return 0
    return clampVolume(sinkAudio.volume * 100)
  }

  function setVolume(val) {
    if (!sinkAudio) return
    sinkAudio.volume = clampVolume(val) / 100
  }

  function toggleMute() {
    if (!sinkAudio) return
    sinkAudio.muted = !sinkAudio.muted
  }

  function syncFromSink() {
    root.volume = volumeFromSink()
    root.muted = sinkAudio ? sinkAudio.muted : false
  }

  readonly property string icon: {
    if (muted) return "󰖁"
    if (volume >= 66) return "󰕾"
    if (volume >= 33) return "󰖀"
    if (volume > 0) return "󰕿"
    return "󰝟"
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
        OsdState.show(root.muted ? "󰖁" : root.icon,
          root.muted ? "MUTED" : "VOLUME " + root.volume + "%")
      }
    }

    function onVolumesChanged() {
      root.volume = root.volumeFromSink()
      if (root.ready && !root.muted) {
        OsdState.show(root.icon, "VOLUME " + root.volume + "%")
      }
    }
  }
}
