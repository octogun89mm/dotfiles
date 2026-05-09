pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property string fallback: ""
  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string baseDir: home + "/.dotfiles/quickshell/.config/quickshell/window-icons"
  readonly property string svgDir: baseDir + "/svg"

  property var apps: []
  property var tray: []
  property var svgs: ({})

  function lookup(list, key) {
    for (let i = 0; i < list.length; i++) {
      const entry = list[i]
      const patterns = entry.patterns || []
      for (let j = 0; j < patterns.length; j++) {
        if (key.includes(patterns[j])) return entry
      }
    }
    return null
  }

  function entryIcon(entry) {
    if (!entry) return fallback
    if (entry.icon) return entry.icon
    if (entry.svg) return "svg:" + entry.svg
    return fallback
  }

  function iconForApp(text) {
    if (!text) return fallback
    return entryIcon(lookup(apps, String(text).toLowerCase()))
  }

  function iconForTray(text) {
    if (!text) return fallback
    return entryIcon(lookup(tray, String(text).toLowerCase()))
  }

  function isSvgRef(text) {
    return typeof text === "string" && text.indexOf("svg:") === 0
  }

  function svgUri(ref, color) {
    const name = isSvgRef(ref) ? ref.slice(4) : ref
    let svg = svgs[name] || ""
    if (!svg) return ""
    if (color) {
      const hex = (typeof color === 'string') ? color : colorHex(color)
      svg = svg.replace(/currentColor/g, hex)
    }
    return "data:image/svg+xml;utf8," + encodeURIComponent(svg)
  }

  function colorHex(c) {
    const r = Math.round(c.r * 255).toString(16).padStart(2, "0")
    const g = Math.round(c.g * 255).toString(16).padStart(2, "0")
    const b = Math.round(c.b * 255).toString(16).padStart(2, "0")
    return "#" + r + g + b
  }

  function parseJson(text, target) {
    try {
      const data = JSON.parse(text || "[]")
      if (Array.isArray(data)) {
        if (target === "apps") root.apps = data
        else if (target === "tray") root.tray = data
      }
    } catch (e) {
      console.warn("WindowIcons: failed to parse", target, "json:", e)
    }
  }

  function loadSvgs() {
    svgLoader.exec(["python3", "-c",
      "import os, json, sys\n" +
      "d = sys.argv[1]\n" +
      "out = {}\n" +
      "if os.path.isdir(d):\n" +
      "    for f in os.listdir(d):\n" +
      "        if f.endswith('.svg'):\n" +
      "            try:\n" +
      "                with open(os.path.join(d, f)) as h: out[f] = h.read()\n" +
      "            except Exception: pass\n" +
      "print(json.dumps(out))",
      root.svgDir
    ])
  }

  Component.onCompleted: loadSvgs()

  FileView {
    path: root.baseDir + "/apps.json"
    watchChanges: true
    onLoaded: root.parseJson(text(), "apps")
    onFileChanged: { reload(); root.parseJson(text(), "apps"); root.loadSvgs() }
  }

  FileView {
    path: root.baseDir + "/tray.json"
    watchChanges: true
    onLoaded: root.parseJson(text(), "tray")
    onFileChanged: { reload(); root.parseJson(text(), "tray"); root.loadSvgs() }
  }

  Process {
    id: svgLoader
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try { root.svgs = JSON.parse(text || "{}") }
        catch (e) { console.warn("WindowIcons: svg load failed:", e) }
      }
    }
  }
}
