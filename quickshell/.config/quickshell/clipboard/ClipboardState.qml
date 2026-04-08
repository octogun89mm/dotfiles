pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool visible: false
  property string screenName: ""
  property string filterText: ""
  property int loadRevision: 0
  property var tempPaths: []

  readonly property alias entries: entriesModel
  readonly property alias filteredEntries: filteredModel

  function normalizePreview(preview) {
    return (preview || "").replace(/\u0000/g, "")
  }

  function previewFor(rawLine) {
    const tabIndex = rawLine.indexOf("\t")
    return normalizePreview(tabIndex >= 0 ? rawLine.slice(tabIndex + 1) : rawLine)
  }

  function entryIdFor(rowIndex, revision) {
    return revision + ":" + rowIndex + ":" + Date.now()
  }

  function indexForEntryId(entryId) {
    for (let i = 0; i < entriesModel.count; i++) {
      if (entriesModel.get(i).entryId === entryId) return i
    }

    return -1
  }

  function matchesFilter(entry) {
    if (!filterText) return true

    const needle = filterText.toLowerCase()
    return (entry.preview || "").toLowerCase().indexOf(needle) >= 0
      || (entry.rawLine || "").toLowerCase().indexOf(needle) >= 0
  }

  function refreshFiltered() {
    filteredModel.clear()

    for (let i = 0; i < entriesModel.count; i++) {
      const entry = entriesModel.get(i)
      if (!matchesFilter(entry)) continue

      filteredModel.append({
        entryId: entry.entryId,
        sourceIndex: i,
        rawLine: entry.rawLine,
        preview: entry.preview,
        isUtf16Text: entry.isUtf16Text,
        isImage: entry.isImage,
        imagePath: entry.imagePath
      })
    }
  }

  function setFilterText(text) {
    filterText = text || ""
    refreshFiltered()
  }

  function show(monitorName) {
    if (monitorName) screenName = monitorName
    setFilterText("")
    if (visible) refreshEntries()
    else visible = true
  }

  function hide() {
    visible = false
  }

  function toggle(monitorName) {
    const targetScreen = monitorName || ""

    if (visible && screenName === targetScreen) {
      hide()
      return
    }

    show(targetScreen)
  }

  function refreshEntries() {
    loadRevision += 1
    entriesModel.clear()
    refreshFiltered()

    listProcess.revision = loadRevision
    listProcess.exec(["cliphist", "list"])
  }

  function markImage(entryId, imagePath) {
    const index = indexForEntryId(entryId)
    if (index < 0) {
      cleanupTempPath(imagePath)
      return
    }

    entriesModel.setProperty(index, "isImage", true)
    entriesModel.setProperty(index, "imagePath", imagePath)
    rememberTempPath(imagePath)
    refreshFiltered()
  }

  function rememberTempPath(path) {
    if (!path) return
    if (tempPaths.indexOf(path) >= 0) return

    const nextPaths = tempPaths.slice()
    nextPaths.push(path)
    tempPaths = nextPaths
  }

  function forgetTempPath(path) {
    if (!path) return

    const nextPaths = tempPaths.filter(function(entryPath) {
      return entryPath !== path
    })

    tempPaths = nextPaths
  }

  function cleanupTempPath(path) {
    if (!path) return

    forgetTempPath(path)
    runCleanup(["/bin/sh", "-c", "rm -f -- \"$1\"", "cleanup", path])
  }

  function cleanupTemps() {
    if (tempPaths.length === 0) return

    const paths = tempPaths.slice()
    tempPaths = []
    runCleanup(["/bin/sh", "-c", "for file do rm -f -- \"$file\"; done", "cleanup"].concat(paths))
  }

  function runCleanup(args) {
    const process = cleanupProcessComponent.createObject(root)
    process.exec(args)
  }

  function parseList(text, revision) {
    if (revision !== loadRevision || !visible) return

    entriesModel.clear()
    const lines = text ? text.split("\n") : []

    for (let i = 0; i < lines.length; i++) {
      const rawLine = lines[i]
      if (!rawLine) continue

      const preview = previewFor(rawLine)
      const entryId = entryIdFor(i, revision)
      const isBinary = preview.indexOf("[[ binary data ") === 0
      const isUtf16Text = !isBinary && rawLine.indexOf("\u0000") >= 0

      entriesModel.append({
        entryId: entryId,
        rawLine: rawLine,
        preview: preview,
        isUtf16Text: isUtf16Text,
        isImage: false,
        imagePath: ""
      })

      if (isBinary) decodeBinaryEntry(rawLine, entryId, i, revision)
    }

    refreshFiltered()
  }

  function decodeBinaryEntry(rawLine, entryId, rowIndex, revision) {
    const tempPath = "/tmp/qs-clip-" + revision + "-" + rowIndex + ".bin"
    const pathPrefix = "/tmp/qs-clip-" + revision + "-" + rowIndex + "."
    const process = decodeProcessComponent.createObject(root, {
      entryId: entryId,
      tempPath: tempPath,
      revision: revision
    })

    process.exec([
      "/bin/sh",
      "-c",
      "if printf '%s\\n' \"$1\" | cliphist decode > \"$2\" 2>/dev/null; then " +
      "mime=$(file --brief --mime-type \"$2\" 2>/dev/null || true); " +
      "path=\"$2\"; " +
      "if [ -n \"$mime\" ] && [ \"${mime#image/}\" != \"$mime\" ]; then " +
      "ext=${mime#image/}; ext=${ext%%+*}; [ \"$ext\" = \"jpeg\" ] && ext=jpg; " +
      "path=\"$3$ext\"; " +
      "mv -f -- \"$2\" \"$path\"; " +
      "fi; " +
      "printf '%s\\t%s\\n' \"$mime\" \"$path\"; " +
      "fi",
      "decode",
      rawLine,
      tempPath,
      pathPrefix
    ])
  }

  function select(index) {
    if (index < 0 || index >= entriesModel.count) return

    const entry = entriesModel.get(index)

    if (entry.isUtf16Text) {
      selectProcess.exec([
        "/bin/sh",
        "-c",
        "printf '%s\\n' \"$1\" | cliphist decode | iconv -f UTF-16LE -t UTF-8 | wl-copy",
        "select",
        entry.rawLine
      ])
    } else {
      selectProcess.exec([
        "/bin/sh",
        "-c",
        "printf '%s\\n' \"$1\" | cliphist decode | wl-copy",
        "select",
        entry.rawLine
      ])
    }

    hide()
  }

  function deleteEntry(index) {
    if (index < 0 || index >= entriesModel.count) return

    const entry = entriesModel.get(index)
    deleteProcess.exec([
      "/bin/sh",
      "-c",
      "printf '%s\\n' \"$1\" | cliphist delete",
      "delete",
      entry.rawLine
    ])

    if (entry.imagePath) cleanupTempPath(entry.imagePath)
    entriesModel.remove(index)
    refreshFiltered()
  }

  function wipeAll() {
    wipeProcess.exec(["cliphist", "wipe"])
    entriesModel.clear()
    refreshFiltered()
    cleanupTemps()
  }

  onVisibleChanged: {
    if (visible) {
      refreshEntries()
    } else {
      setFilterText("")
      cleanupTemps()
    }
  }

  ListModel {
    id: entriesModel
  }

  ListModel {
    id: filteredModel
  }

  Process {
    id: listProcess
    property int revision: 0

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseList(text, listProcess.revision)
    }
  }

  Process {
    id: selectProcess
  }

  Process {
    id: deleteProcess
  }

  Process {
    id: wipeProcess
  }

  Component {
    id: decodeProcessComponent

    Process {
      id: decodeProcess

      property string entryId: ""
      property string tempPath: ""
      property int revision: 0
      property string mimeType: ""
      property string outputPath: ""

      stdout: StdioCollector {
        waitForEnd: true
        onStreamFinished: {
          const line = text.trim()
          const separatorIndex = line.indexOf("\t")

          if (separatorIndex >= 0) {
            decodeProcess.mimeType = line.slice(0, separatorIndex)
            decodeProcess.outputPath = line.slice(separatorIndex + 1)
          } else {
            decodeProcess.mimeType = line
            decodeProcess.outputPath = decodeProcess.tempPath
          }
        }
      }

      onExited: function(exitCode) {
        const activeRevision = revision === root.loadRevision && root.visible

        if (exitCode === 0 && activeRevision && mimeType.indexOf("image/") === 0) {
          root.markImage(entryId, outputPath || tempPath)
        } else {
          root.cleanupTempPath(outputPath || tempPath)
        }

        destroy()
      }
    }
  }

  Component {
    id: cleanupProcessComponent

    Process {
      onExited: destroy()
    }
  }
}
