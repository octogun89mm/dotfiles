import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root
  implicitWidth: layout.implicitWidth + Theme.padSm * 2
  implicitHeight: Theme.chipHeight

  property string currentGovernor: "..."

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: {
      pollProcess.running = false
      pollProcess.exec(["cat", "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"])
    }
  }

  Component.onCompleted: {
    pollProcess.exec(["cat", "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"])
  }

  Process {
    id: pollProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (text) {
          root.currentGovernor = text.trim()
        }
      }
    }
  }

  Process {
    id: toggleProcess
    onExited: {
      pollProcess.running = false
      pollProcess.exec(["cat", "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"])
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: Theme.radiusMd
    color: mouseArea.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06) : "transparent"
  }

  Row {
    id: layout
    anchors.centerIn: parent
    spacing: 6

    Text {
      text: root.currentGovernor === "performance" ? "󰓅" : "󰾆"
      color: root.currentGovernor === "performance" ? Theme.accent : Theme.textDim
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontMd
      verticalAlignment: Text.AlignVCenter
    }

    Text {
      text: root.currentGovernor === "performance" ? "PERF" : "PWR"
      color: root.currentGovernor === "performance" ? Theme.text : Theme.textDim
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontSmall
      font.bold: true
      verticalAlignment: Text.AlignVCenter
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      toggleProcess.running = false
      toggleProcess.exec(["pkexec", "sh", "-c", "CURRENT=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor); if [ \"$CURRENT\" = \"powersave\" ]; then echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; else echo powersave | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; fi"])
    }
  }
}
