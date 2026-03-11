import QtQuick
import Quickshell
import "../wallust.js" as Wallust

Rectangle {
  id: root

  property bool pinned: false

  color: Wallust.base00
  border.width: 2
  border.color: pinned ? Wallust.base0E : Wallust.base03

  property date viewDate: new Date()
  readonly property int viewYear: viewDate.getFullYear()
  readonly property int viewMonth: viewDate.getMonth()

  readonly property date today: clock.date

  implicitWidth: 230
  implicitHeight: calColumn.implicitHeight + 20

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  function daysInMonth(year, month) {
    return new Date(year, month + 1, 0).getDate()
  }

  function firstDayOfWeek(year, month) {
    return new Date(year, month, 1).getDay()
  }

  function prevMonth() {
    var d = new Date(viewYear, viewMonth - 1, 1)
    viewDate = d
  }

  function nextMonth() {
    var d = new Date(viewYear, viewMonth + 1, 1)
    viewDate = d
  }

  Column {
    id: calColumn
    anchors.centerIn: parent
    spacing: 6

    Row {
      width: 200
      height: 24

      Item {
        width: 24
        height: 24

        Text {
          anchors.centerIn: parent
          text: "󰅁"
          color: Wallust.base04
          font.family: "Symbols Nerd Font Mono"
          font.pixelSize: 14
        }

        MouseArea {
          anchors.fill: parent
          onClicked: root.prevMonth()
        }
      }

      Text {
        width: parent.width - 48
        height: 24
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: Qt.locale().monthName(root.viewMonth, Locale.LongFormat) + " " + root.viewYear
        color: Wallust.base05
        font.family: "Roboto Mono"
        font.pixelSize: 12
        font.bold: true
      }

      Item {
        width: 24
        height: 24

        Text {
          anchors.centerIn: parent
          text: "󰅂"
          color: Wallust.base04
          font.family: "Symbols Nerd Font Mono"
          font.pixelSize: 14
        }

        MouseArea {
          anchors.fill: parent
          onClicked: root.nextMonth()
        }
      }
    }

    Grid {
      id: dayHeaders
      columns: 7
      columnSpacing: 0
      rowSpacing: 0
      width: 196

      Repeater {
        model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

        Text {
          required property var modelData
          width: 28
          height: 20
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          text: modelData
          color: Wallust.base03
          font.family: "Roboto Mono"
          font.pixelSize: 10
          font.bold: true
        }
      }
    }

    Grid {
      id: dayGrid
      columns: 7
      columnSpacing: 0
      rowSpacing: 0
      width: 196

      Repeater {
        model: 42

        Rectangle {
          required property int index

          readonly property int dayOffset: index - root.firstDayOfWeek(root.viewYear, root.viewMonth)
          readonly property int dayNum: dayOffset + 1
          readonly property bool inMonth: dayNum >= 1 && dayNum <= root.daysInMonth(root.viewYear, root.viewMonth)
          readonly property bool isToday: inMonth
            && root.today.getFullYear() === root.viewYear
            && root.today.getMonth() === root.viewMonth
            && root.today.getDate() === dayNum

          width: 28
          height: 28
          color: isToday ? Wallust.base0D : "transparent"

          Text {
            anchors.centerIn: parent
            text: inMonth ? dayNum.toString() : ""
            color: isToday ? Wallust.base00 : Wallust.base05
            font.family: "Roboto Mono"
            font.pixelSize: 11
          }
        }
      }
    }
  }
}
