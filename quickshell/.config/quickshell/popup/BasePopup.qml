import QtQuick
import Quickshell
import ".." as Root

PopupWindow {
  id: root

  required property var shellParentWindow
  required property var triggerItem
  property bool pinned: false
  property bool triggerHovered: false
  property int anchorOffsetX: 0
  property int anchorOffsetY: 10
  property Component popupContent

  readonly property bool popupHovered: popupHover.containsMouse
  readonly property bool showPopup: pinned || triggerHovered || popupHovered || closeDelay.running
  readonly property color popupBorderColor: pinned ? Wallust.base0C : Wallust.base02

  function syncLoadedItem() {
    if (!contentLoader.item) return

    if ("active" in contentLoader.item) {
      contentLoader.item.active = Qt.binding(function() { return root.visible })
    }

    if ("pinned" in contentLoader.item) {
      contentLoader.item.pinned = Qt.binding(function() { return root.pinned })
    }

    if ("border" in contentLoader.item && contentLoader.item.border) {
      contentLoader.item.border.color = Qt.binding(function() { return root.popupBorderColor })
    }
  }

  anchor.window: shellParentWindow
  anchor.item: triggerItem
  anchor.rect.x: triggerItem ? anchorOffsetX : 0
  anchor.rect.y: triggerItem ? triggerItem.height + anchorOffsetY : 0
  color: "transparent"
  visible: showPopup || slideAnim.running
  implicitWidth: contentLoader.item ? contentLoader.item.implicitWidth : 0
  implicitHeight: contentLoader.item ? contentLoader.item.implicitHeight : 0

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

    Loader {
      id: contentLoader
      sourceComponent: root.popupContent
      y: root.showPopup ? 0 : -(item ? item.implicitHeight : 0)
      onLoaded: root.syncLoadedItem()

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
