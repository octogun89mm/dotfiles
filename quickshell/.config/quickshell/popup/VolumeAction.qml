import QtQuick
import ".." as Root
import "../wallust.js" as Wallust

Rectangle {
  id: root

  property bool active: false

  color: Wallust.base03
  implicitWidth: 132
  implicitHeight: 54

  Row {
    anchors.fill: parent
    anchors.leftMargin: 10
    anchors.rightMargin: 6
    anchors.topMargin: 8
    anchors.bottomMargin: 8
    spacing: 8

    Item {
      width: 18
      height: parent.height
      anchors.verticalCenter: parent.verticalCenter

      Text {
        anchors.centerIn: parent
        text: Root.VolumeState.muted ? "󰖁" : Root.VolumeState.volume >= 66 ? "󰕾" : Root.VolumeState.volume >= 33 ? "󰖀" : "󰕿"
        color: Root.VolumeState.muted ? Wallust.base03 : Wallust.accent
        font.family: "Symbols Nerd Font Mono"
        font.pixelSize: 16
      }

      MouseArea {
        anchors.fill: parent
        onClicked: Root.VolumeState.toggleMute()
      }
    }

    Item {
      width: parent.width - 18 - 18 - parent.spacing * 2
      height: parent.height
      anchors.verticalCenter: parent.verticalCenter

      Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: 1

        Text {
          text: "VOLUME"
          width: parent.width
          elide: Text.ElideRight
          color: Wallust.base04
          font.family: "Iosevka"
          font.pixelSize: 10
          font.bold: true
        }

        Text {
          text: Root.VolumeState.muted ? "MUTED" : Root.VolumeState.volume + "%"
          width: parent.width
          elide: Text.ElideRight
          color: Root.VolumeState.muted ? Wallust.base03 : Wallust.base05
          font.family: "Iosevka"
          font.pixelSize: 11
          font.bold: true
        }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: Root.VolumeState.toggleMute()
        onWheel: wheel => {
          const step = 5
          let target = Root.VolumeState.volume
          if (wheel.angleDelta.y > 0) {
            target = Math.min(target + step, 99)
          } else if (wheel.angleDelta.y < 0) {
            target = Math.max(target - step, 0)
          }
          Root.VolumeState.setVolume(target)
        }
      }
    }

    Item {
      width: 18
      height: parent.height
      anchors.verticalCenter: parent.verticalCenter

      Text {
        anchors.centerIn: parent
        text: Root.VolumeState.sinkName.toLowerCase().indexOf("razer") !== -1 ? "󰋋" : "󰓃"
        color: Wallust.base05
        font.family: "Symbols Nerd Font Mono"
        font.pixelSize: 12
      }

      MouseArea {
        anchors.fill: parent
        onClicked: Root.VolumeState.switchSink()
      }
    }
  }
}
