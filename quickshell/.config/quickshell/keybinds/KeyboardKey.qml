import QtQuick
import "../wallust.js" as Wallust

Rectangle {
  id: root

  required property var keyModel
  property var bindData: null
  property bool modifierActive: false

  readonly property bool active: bindData !== null
  readonly property string category: active ? bindData.category : (modifierActive ? "modifier" : "idle")
  readonly property color fillColor: {
    switch (category) {
    case "modifier":
      return Wallust.base08
    case "workspace":
      return Wallust.base0A
    case "layout":
      return Wallust.base0C
    case "window":
      return Wallust.base09
    case "launcher":
      return Wallust.base0E
    case "system":
      return Wallust.base0B
    case "mouse":
      return Wallust.base0F
    case "plain":
      return Wallust.base03
    case "other":
      return Wallust.base0D
    default:
      return Wallust.base01
    }
  }
  readonly property color textColor: active || modifierActive ? Wallust.base00 : Wallust.base05
  readonly property string description: active ? bindData.desc : ""
  readonly property string displayDescription: hyphenateText(description, 9)

  function hyphenateWord(word, maxChunk) {
    if (!word || word.length <= maxChunk) return word

    let output = ""
    let remaining = word

    while (remaining.length > maxChunk) {
      output += remaining.slice(0, maxChunk - 1) + "-\n"
      remaining = remaining.slice(maxChunk - 1)
    }

    return output + remaining
  }

  function hyphenateText(text, maxChunk) {
    if (!text) return ""

    return text
      .split("\n")
      .map(function(line) {
        return line
          .split(" ")
          .map(function(word) { return hyphenateWord(word, maxChunk) })
          .join(" ")
      })
      .join("\n")
  }

  color: active || modifierActive ? fillColor : Wallust.base01
  border.width: 2
  border.color: active || modifierActive ? fillColor : Wallust.base02
  implicitWidth: Math.round(60 * (keyModel.width || 1))
  implicitHeight: 64

  Text {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.leftMargin: 7
    anchors.topMargin: 7
    width: parent.width - 14
    visible: !!root.description
    text: root.displayDescription
    color: root.textColor
    font.family: "Iosevka"
    font.pixelSize: 8
    wrapMode: Text.Wrap
    maximumLineCount: 3
    lineHeight: 0.9
    elide: Text.ElideRight
  }

  Text {
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.leftMargin: 7
    anchors.bottomMargin: 6
    text: keyModel.label
    color: root.textColor
    font.family: "Iosevka"
    font.pixelSize: 11
    font.bold: true
  }
}
