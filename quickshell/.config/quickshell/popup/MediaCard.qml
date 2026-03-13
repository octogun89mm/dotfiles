import QtQuick
import ".." as Root
import "../wallust.js" as Wallust

Rectangle {
  id: root

  property bool active: false
  readonly property int contentPadding: 12

  color: Wallust.base03
  implicitHeight: Math.max(albumArtFrame.height, detailsColumn.implicitHeight) + (contentPadding * 2)

  Row {
    id: contentRow
    anchors.fill: parent
    anchors.margins: root.contentPadding
    spacing: 12

    Item {
      id: albumArtSlot
      width: 96
      height: parent.height

      Rectangle {
        id: albumArtFrame
        anchors.centerIn: parent
        width: 96
        height: 96
        color: Wallust.base01
        border.width: 2
        border.color: Root.MediaState.playing ? Wallust.base0D : Wallust.base03

        Image {
          id: albumArtImage
          anchors.fill: parent
          source: Root.MediaState.albumArt
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          cache: false
          visible: Root.MediaState.albumArt !== ""
        }

        Text {
          anchors.centerIn: parent
          visible: !albumArtImage.visible
          text: Root.MediaState.playing ? "󰎆" : "󰐊"
          color: Wallust.base04
          font.family: "Symbols Nerd Font Mono"
          font.pixelSize: 24
        }
      }
    }

    Column {
      id: detailsColumn
      width: contentRow.width - albumArtSlot.width - contentRow.spacing
      spacing: 8

      Text {
        text: "MEDIA"
        color: Wallust.base04
        font.family: "Roboto Mono"
        font.pixelSize: 10
        font.bold: true
      }

      Text {
        width: parent.width
        text: Root.MediaState.available ? (Root.MediaState.title || "NO TITLE") : "NO MEDIA"
        elide: Text.ElideRight
        color: Wallust.base05
        font.family: "Roboto Mono"
        font.pixelSize: 13
        font.bold: true
      }

      Text {
        width: parent.width
        text: Root.MediaState.available ? (Root.MediaState.artist || Root.MediaState.playerName || "UNKNOWN") : "OPEN A PLAYER"
        elide: Text.ElideRight
        color: Wallust.base04
        font.family: "Roboto Mono"
        font.pixelSize: 10
      }

      Text {
        width: parent.width
        text: Root.MediaState.playing ? "PLAYING" : Root.MediaState.available ? "PAUSED" : ""
        color: Root.MediaState.playing ? Wallust.base0D : Wallust.base04
        font.family: "Roboto Mono"
        font.pixelSize: 10
        font.bold: true
        visible: text !== ""
      }

      Row {
        id: controlsRow
        width: parent.width
        spacing: 8

        Repeater {
          model: [
            { icon: "󰒮", action: function() { Root.MediaState.previous() } },
            { icon: Root.MediaState.playing ? "󰏤" : "󰐊", action: function() { Root.MediaState.playPause() } },
            { icon: "󰒭", action: function() { Root.MediaState.next() } }
          ]

          Rectangle {
            required property var modelData

            width: 34
            height: 32
            color: "transparent"
            border.width: 2
            border.color: Wallust.base01

            Text {
              anchors.centerIn: parent
              text: modelData.icon
              color: Wallust.base05
              font.family: "Symbols Nerd Font Mono"
              font.pixelSize: 15
            }

            MouseArea {
              anchors.fill: parent
              enabled: Root.MediaState.available
              onClicked: modelData.action()
            }
          }
        }
      }
    }
  }
}
