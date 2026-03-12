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

  function firstVisibleDate() {
    return new Date(viewYear, viewMonth, 1 - firstDayOfWeek(viewYear, viewMonth))
  }

  function cellDate(index) {
    const start = firstVisibleDate()
    return new Date(start.getFullYear(), start.getMonth(), start.getDate() + index)
  }

  function weekDate(row) {
    return cellDate(row * 7 + 1)
  }

  function isSameDate(a, b) {
    return a.getFullYear() === b.getFullYear()
      && a.getMonth() === b.getMonth()
      && a.getDate() === b.getDate()
  }

  function isoWeekNumber(date) {
    const target = new Date(date.getFullYear(), date.getMonth(), date.getDate())
    const dayNumber = (target.getDay() + 6) % 7
    target.setDate(target.getDate() - dayNumber + 3)
    const firstThursday = new Date(target.getFullYear(), 0, 4)
    const firstDayNumber = (firstThursday.getDay() + 6) % 7
    firstThursday.setDate(firstThursday.getDate() - firstDayNumber + 3)
    return 1 + Math.round((target - firstThursday) / 604800000)
  }

  function rowContainsToday(row) {
    for (let i = 0; i < 7; i++) {
      if (isSameDate(cellDate(row * 7 + i), today)) return true
    }

    return false
  }

  function goToToday() {
    viewDate = new Date(today.getFullYear(), today.getMonth(), 1)
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
      width: 224
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
        width: parent.width - 96
        height: 24
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: Qt.locale().monthName(root.viewMonth, Locale.LongFormat) + " " + root.viewYear
        color: Wallust.base05
        font.family: "Roboto Mono"
        font.pixelSize: 12
        font.bold: true
      }

      Rectangle {
        width: 48
        height: 24
        color: "transparent"
        border.width: 2
        border.color: Wallust.base01

        Text {
          anchors.centerIn: parent
          text: "TODAY"
          color: Wallust.base05
          font.family: "Roboto Mono"
          font.pixelSize: 9
          font.bold: true
        }

        MouseArea {
          anchors.fill: parent
          onClicked: root.goToToday()
        }
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
      columns: 8
      columnSpacing: 0
      rowSpacing: 0
      width: 224

      Text {
        width: 28
        height: 20
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: "Wk"
        color: Wallust.base03
        font.family: "Roboto Mono"
        font.pixelSize: 10
        font.bold: true
      }

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

    Column {
      width: 224
      spacing: 0

      Repeater {
        model: 6

        Rectangle {
          required property int index

          readonly property date rowDate: root.weekDate(index)
          readonly property bool currentWeek: root.rowContainsToday(index)

          width: 224
          height: 28
          color: currentWeek ? Wallust.base01 : "transparent"

          Row {
            id: weekRow
            anchors.fill: parent
            property int rowIndex: parent.index
            spacing: 0

            Text {
              width: 28
              height: 28
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
              text: root.isoWeekNumber(parent.parent.rowDate)
              color: Wallust.base03
              font.family: "Roboto Mono"
              font.pixelSize: 10
              font.bold: true
            }

            Repeater {
              model: 7

              Rectangle {
                required property int index

                readonly property date dateValue: root.cellDate((weekRow.rowIndex * 7) + index)
                readonly property bool inMonth: dateValue.getMonth() === root.viewMonth
                  && dateValue.getFullYear() === root.viewYear
                readonly property bool isToday: root.isSameDate(dateValue, root.today)

                width: 28
                height: 28
                color: isToday ? Wallust.base0D : "transparent"

                Text {
                  anchors.centerIn: parent
                  text: parent.dateValue.getDate().toString()
                  color: parent.isToday ? Wallust.base00 : parent.inMonth ? Wallust.base05 : Wallust.base03
                  font.family: "Roboto Mono"
                  font.pixelSize: 11
                }
              }
            }
          }
        }
      }
    }
  }
}
