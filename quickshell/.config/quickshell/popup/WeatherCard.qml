import QtQuick
import Quickshell
import Quickshell.Io
import "../wallust.js" as Wallust

Rectangle {
  id: root
  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string weatherScript: home + "/.dotfiles/eww/.config/eww/shell/bar_weather.sh"

  property bool active: false
  property string weatherIcon: ""
  property string weatherText: "..."
  property string weatherDesc: ""
  property string feelsLike: "--"
  property string humidity: "--"
  property string wind: "--"

  color: Wallust.base03
  implicitHeight: 210

  function refreshWeather() {
    weatherProcess.exec([weatherScript])
  }

  function parseWeather(text) {
    if (!text || !text.trim()) return
    try {
      const data = JSON.parse(text)
      weatherIcon = data.icon || ""
      weatherText = data.text || "N/A"
      weatherDesc = data.desc || ""
      feelsLike = data.feels || "--"
      humidity = data.humidity || "--"
      wind = data.wind || "--"
    } catch (e) {
      console.warn("WeatherCard: failed to parse JSON:", e)
    }
  }

  onActiveChanged: if (active) refreshWeather()

  Timer {
    interval: 1800000
    running: root.active
    repeat: true
    onTriggered: root.refreshWeather()
  }

  Process {
    id: weatherProcess

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseWeather(text)
    }
  }

  Column {
    id: content
    anchors.fill: parent
    anchors.margins: 14
    spacing: 10

    Text {
      text: "WEATHER"
      color: Wallust.base04
      font.family: "Roboto Mono"
      font.pixelSize: 10
      font.bold: true
    }

    Text {
      text: root.weatherIcon
      color: Wallust.base0D
      font.family: "Weather Icons"
      font.pixelSize: 40
      horizontalAlignment: Text.AlignHCenter
      width: parent.width
    }

    Text {
      text: root.weatherText
      color: Wallust.base05
      font.family: "Roboto Mono"
      font.pixelSize: 20
      font.bold: true
      horizontalAlignment: Text.AlignHCenter
      width: parent.width
    }

    Text {
      text: root.weatherDesc
      color: Wallust.base04
      font.family: "Roboto Mono"
      font.pixelSize: 11
      horizontalAlignment: Text.AlignHCenter
      width: parent.width
    }

    Item {
      width: 1
      height: Math.max(0, parent.height - y - footer.implicitHeight)
    }

    Row {
      id: footer
      width: parent.width
      spacing: 18

      Column {
        width: (parent.width - parent.spacing * 2) / 3
        spacing: 2
        Text { text: "FEELS"; color: Wallust.base04; font.family: "Roboto Mono"; font.pixelSize: 9; font.bold: true }
        Text { width: parent.width; text: root.feelsLike + "°C"; color: Wallust.base05; font.family: "Roboto Mono"; font.pixelSize: 11; font.bold: true }
      }

      Column {
        width: (parent.width - parent.spacing * 2) / 3
        spacing: 2
        Text { text: "HUMID"; color: Wallust.base04; font.family: "Roboto Mono"; font.pixelSize: 9; font.bold: true }
        Text { width: parent.width; text: root.humidity + "%"; color: Wallust.base05; font.family: "Roboto Mono"; font.pixelSize: 11; font.bold: true }
      }

      Column {
        width: (parent.width - parent.spacing * 2) / 3
        spacing: 2
        Text { text: "WIND"; color: Wallust.base04; font.family: "Roboto Mono"; font.pixelSize: 9; font.bold: true }
        Text { width: parent.width; text: root.wind + " km/h"; color: Wallust.base05; font.family: "Roboto Mono"; font.pixelSize: 11; font.bold: true }
      }
    }
  }
}
