import QtQuick
import Quickshell
import "../wallust.js" as Wallust
import ".." as Root

Rectangle {
  id: root

  property bool pinned: false

  color: Wallust.base00
  border.width: 2
  border.color: pinned ? Wallust.base0E : Wallust.base03

  property date viewDate: new Date()
  readonly property int viewYear: viewDate.getFullYear()
  readonly property int viewMonth: viewDate.getMonth()
  readonly property int cellSize: 28
  readonly property int weekColumnWidth: 28
  readonly property int gridWidth: weekColumnWidth + cellSize * 7
  readonly property int headerHeight: 22

  readonly property date today: clock.date
  property date selectedDate: today
  property string selectedDateKey: dateKey(selectedDate)

  implicitWidth: gridWidth + 20
  implicitHeight: calColumn.implicitHeight + 20

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Component.onCompleted: fetchCalendarEvents()

  function dateKey(d) {
    const y = d.getFullYear()
    const m = String(d.getMonth() + 1).padStart(2, "0")
    const day = String(d.getDate()).padStart(2, "0")
    return y + "-" + m + "-" + day
  }

  function fetchCalendarEvents() {
    const start = firstVisibleDate()
    Root.CalendarState.fetchRange(dateKey(start), 42)
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
    selectedDate = today
    fetchCalendarEvents()
  }

  function firstDayOfWeek(year, month) {
    return new Date(year, month, 1).getDay()
  }

  function calendarColor(calendarName) {
    const colors = [
      Wallust.base0E,
      Wallust.base0B,
      Wallust.base0A,
      Wallust.base0D,
      Wallust.base08,
      Wallust.base0C
    ]
    const name = String(calendarName || "default")
    var hash = 0
    for (let i = 0; i < name.length; i++) {
      hash = ((hash << 5) - hash) + name.charCodeAt(i)
      hash |= 0
    }

    return colors[Math.abs(hash) % colors.length]
  }

  function rebuildEventList() {
    eventListModel.clear()
    const events = Root.CalendarState.getEvents(selectedDateKey)
    for (let i = 0; i < events.length; i++) {
      eventListModel.append({
        title: events[i].title,
        startTime: events[i].startTime,
        endTime: events[i].endTime,
        allDay: events[i].allDay,
        calendar: events[i].calendar
      })
    }
  }

  onSelectedDateKeyChanged: rebuildEventList()

  Connections {
    target: Root.CalendarState
    function onRevisionChanged() { root.rebuildEventList() }
  }

  function prevMonth() {
    var d = new Date(viewYear, viewMonth - 1, 1)
    viewDate = d
    fetchCalendarEvents()
  }

  function nextMonth() {
    var d = new Date(viewYear, viewMonth + 1, 1)
    viewDate = d
    fetchCalendarEvents()
  }

  Column {
    id: calColumn
    anchors.centerIn: parent
    spacing: 6

    Row {
      width: root.gridWidth
      height: 24

      Item {
        width: root.cellSize
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
        width: parent.width - root.cellSize * 2 - 48
        height: 24
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: Qt.locale().monthName(root.viewMonth, Locale.LongFormat) + " " + root.viewYear
        color: Wallust.base05
        font.family: "Liberation Mono"
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
          font.family: "Liberation Mono"
          font.pixelSize: 9
          font.bold: true
        }

        MouseArea {
          anchors.fill: parent
          onClicked: root.goToToday()
        }
      }

      Item {
        width: root.cellSize
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
      width: root.gridWidth

      Text {
        width: root.weekColumnWidth
        height: root.headerHeight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: "Wk"
        color: Wallust.base03
        font.family: "Liberation Mono"
        font.pixelSize: 10
        font.bold: true
      }

      Repeater {
        model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

        Text {
          required property var modelData
          width: root.cellSize
          height: root.headerHeight
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          text: modelData
          color: Wallust.base03
          font.family: "Liberation Mono"
          font.pixelSize: 10
          font.bold: true
        }
      }
    }

    Column {
      width: root.gridWidth
      spacing: 0

      Repeater {
        model: 6

        Rectangle {
          required property int index

          readonly property date rowDate: root.weekDate(index)
          readonly property bool currentWeek: root.rowContainsToday(index)

          width: root.gridWidth
          height: root.cellSize
          color: "transparent"

          Row {
            id: weekRow
            anchors.fill: parent
            property int rowIndex: parent.index
            spacing: 0

            Text {
              width: root.weekColumnWidth
              height: root.cellSize
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
              text: root.isoWeekNumber(parent.parent.rowDate)
              color: Wallust.base03
              font.family: "Liberation Mono"
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
                readonly property bool isSelected: root.isSameDate(dateValue, root.selectedDate)
                readonly property string cellDateKey: root.dateKey(dateValue)
                readonly property var cellEvents: Root.CalendarState.eventsByDate[cellDateKey] || []
                readonly property bool cellHasEvents: Root.CalendarState.revision >= 0 && cellEvents.length > 0
                readonly property color cellEventColor: cellHasEvents ? root.calendarColor(cellEvents[0].calendar) : Wallust.accent
                readonly property bool currentWeek: root.rowContainsToday(weekRow.rowIndex)

                width: root.cellSize
                height: root.cellSize
                color: isToday ? Wallust.accent
                     : isSelected ? Wallust.base02
                     : currentWeek ? Wallust.base01
                     : "transparent"
                border.width: 1
                border.color: isToday || isSelected ? Wallust.base04 : Wallust.base00

                Text {
                  anchors.centerIn: parent
                  text: parent.dateValue.getDate().toString()
                  color: parent.isToday ? Wallust.base00 : parent.inMonth ? Wallust.base05 : Wallust.base03
                  font.family: "Liberation Mono"
                  font.pixelSize: 11
                }

                Rectangle {
                  width: 4
                  height: 4
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.bottom: parent.bottom
                  anchors.bottomMargin: 2
                  color: parent.isToday ? Wallust.base00 : parent.cellEventColor
                  visible: parent.cellHasEvents
                }

                MouseArea {
                  anchors.fill: parent
                  onClicked: root.selectedDate = parent.dateValue
                }
              }
            }
          }
        }
      }
    }

    Rectangle {
      width: root.gridWidth
      height: 1
      color: Wallust.base02
      visible: eventListModel.count > 0
    }

    Column {
      id: eventSection
      width: root.gridWidth
      spacing: 2
      visible: eventListModel.count > 0

      Text {
        text: Qt.formatDate(root.selectedDate, "ddd, MMM d")
        color: Wallust.base04
        font.family: "Liberation Mono"
        font.pixelSize: 10
        font.bold: true
      }

      Repeater {
        model: ListModel { id: eventListModel }

        Rectangle {
          width: root.gridWidth
          height: eventItemCol.implicitHeight + 6
          color: Wallust.base01

          Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 4
            color: root.calendarColor(model.calendar)
          }

          Column {
            id: eventItemCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 10
            anchors.rightMargin: 6

            Text {
              width: parent.width
              text: model.title
              color: Wallust.base05
              font.family: "Liberation Mono"
              font.pixelSize: 10
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              text: model.allDay ? "ALL DAY" : model.startTime + " \u2013 " + model.endTime
              color: Wallust.base04
              font.family: "Liberation Mono"
              font.pixelSize: 9
            }

            Text {
              width: parent.width
              visible: model.calendar !== ""
              text: model.calendar
              color: root.calendarColor(model.calendar)
              font.family: "Liberation Mono"
              font.pixelSize: 9
              font.bold: true
              elide: Text.ElideRight
            }
          }
        }
      }
    }
  }
}
