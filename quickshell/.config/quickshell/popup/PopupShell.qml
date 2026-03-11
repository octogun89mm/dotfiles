import QtQuick
import Quickshell
import "../wallust.js" as Wallust

PopupWindow {
  id: root

  required property var shellParentWindow
  required property var triggerItem
  property bool pinned: false
  property bool triggerHovered: false

  readonly property bool popupHovered: popupHover.containsMouse
  property bool showPopup: pinned || triggerHovered || popupHovered || closeDelay.running

  anchor.window: shellParentWindow
  anchor.item: triggerItem
  anchor.rect.x: triggerItem ? Math.round((triggerItem.width - implicitWidth) / 2) : 0
  anchor.rect.y: triggerItem ? triggerItem.height + 11 : 0
  color: "transparent"
  visible: showPopup || slideAnim.running
  implicitWidth: popupBody.implicitWidth
  implicitHeight: popupBody.implicitHeight

  onTriggerHoveredChanged: {
    if (triggerHovered) {
      closeDelay.stop()
    } else if (!pinned && !popupHovered) {
      closeDelay.restart()
    }
  }

  onPopupHoveredChanged: {
    if (popupHovered) {
      closeDelay.stop()
    } else if (!pinned && !triggerHovered) {
      closeDelay.restart()
    }
  }

  Timer {
    id: closeDelay
    interval: 180
    repeat: false
  }

  Item {
    anchors.fill: parent
    clip: true

    MouseArea {
      id: popupHover
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.NoButton
    }

    BarPopup {
      id: popupBody
      width: parent.width
      active: root.visible
      pinned: root.pinned
      y: root.showPopup ? 0 : -height

      Behavior on y {
        NumberAnimation {
          id: slideAnim
          duration: 150
          easing.type: Easing.OutQuad
        }
      }
    }
  }
}
