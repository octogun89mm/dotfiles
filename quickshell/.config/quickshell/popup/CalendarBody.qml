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

  readonly property date today: clock.date
  property date selectedDate: today
  property string selectedDateKey: dateKey(selectedDate)

  implicitWidth: 244
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
        font.family: "Iosevka"
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
          font.family: "Iosevka"
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
        font.family: "Iosevka"
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
          font.family: "Iosevka"
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
              font.family: "Iosevka"
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
                readonly property bool cellHasEvents: Root.CalendarState.revision >= 0
                  && (Root.CalendarState.eventsByDate[cellDateKey] || []).length > 0

                width: 28
                height: 28
                color: isToday ? Wallust.accent
                     : isSelected ? Wallust.base02
                     : "transparent"

                Text {
                  anchors.centerIn: parent
                  text: parent.dateValue.getDate().toString()
                  color: parent.isToday ? Wallust.base00 : parent.inMonth ? Wallust.base05 : Wallust.base03
                  font.family: "Iosevka"
                  font.pixelSize: 11
                }

                Rectangle {
                  width: 4
                  height: 4
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.bottom: parent.bottom
                  anchors.bottomMargin: 2
                  color: parent.isToday ? Wallust.base00 : Wallust.accent
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
      width: 224
      height: 1
      color: Wallust.base02
      visible: eventListModel.count > 0
    }

    Column {
      id: eventSection
      width: 224
      spacing: 2
      visible: eventListModel.count > 0

      Text {
        text: Qt.formatDate(root.selectedDate, "ddd, MMM d")
        color: Wallust.base04
        font.family: "Iosevka"
        font.pixelSize: 10
        font.bold: true
      }

      Repeater {
        model: ListModel { id: eventListModel }

        Rectangle {
          width: 224
          height: eventItemCol.implicitHeight + 6
          color: Wallust.base01

          Column {
            id: eventItemCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 6
            anchors.rightMargin: 6

            Text {
              width: parent.width
              text: model.title
              color: Wallust.base05
              font.family: "Iosevka"
              font.pixelSize: 10
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              text: model.allDay ? "ALL DAY" : model.startTime + " \u2013 " + model.endTime
              color: Wallust.base04
              font.family: "Iosevka"
              font.pixelSize: 9
            }
          }
        }
      }
    }
  }
}
