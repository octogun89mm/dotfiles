pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property var eventsByDate: ({})
  property int revision: 0
  property string lastCmd: ""

  function getEvents(dateStr) {
    return eventsByDate[dateStr] || []
  }

  function fetchRange(startDateStr, days) {
    lastCmd = "khal list -df '' -f '{start-date}|{start-time}|{end-date}|{end-time}|{title}|{calendar}' " + startDateStr + " " + days + "d"

    khalProcess.exec(["/bin/sh", "-c", lastCmd])
  }

  function parseEvents(text) {

    var result = {}
    if (!text || !text.trim()) {
      eventsByDate = result
      revision = revision + 1
      return
    }

    var lines = text.trim().split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (!line) continue

      var parts = line.split("|")
      if (parts.length < 6) continue

      var ev = {
        startDate: parts[0],
        startTime: parts[1],
        endDate: parts[2],
        endTime: parts[3],
        title: parts[4],
        calendar: parts[5].trim(),
        allDay: !parts[1]
      }

      if (!result[ev.startDate]) result[ev.startDate] = []
      result[ev.startDate].push(ev)
    }


    eventsByDate = result
    revision = revision + 1

  }

  Timer {
    interval: 300000
    running: root.lastCmd !== ""
    repeat: true
    onTriggered: khalProcess.exec(["/bin/sh", "-c", root.lastCmd])
  }

  Process {
    id: khalProcess

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseEvents(text)
    }
  }
}
