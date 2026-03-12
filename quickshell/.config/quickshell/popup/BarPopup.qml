import QtQuick
import "../wallust.js" as Wallust

Rectangle {
  id: root

  property bool active: false
  property bool pinned: false

  color: Wallust.base00
  border.width: 2
  border.color: pinned ? Wallust.base0E : Wallust.base03
  implicitWidth: 590
  implicitHeight: content.implicitHeight + 24

  Column {
    id: content
    anchors.fill: parent
    anchors.margins: 12
    spacing: 12

    QuickActions {
      width: parent.width
      active: root.active
    }

    Row {
      id: bodyRow
      spacing: 12
      height: leftColumn.implicitHeight

      Column {
        id: leftColumn
        spacing: 10

        MediaCard {
          id: mediaCard
          active: root.active
        }

        WeatherCard {
          id: weatherCard
          active: root.active
        }

        DiskCard {
          id: diskCard
          active: root.active
        }
      }

      SystemColumn {
        id: systemColumn
        active: root.active
        height: bodyRow.height
      }
    }
  }
}
