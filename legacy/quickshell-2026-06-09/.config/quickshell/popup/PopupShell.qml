import QtQuick

BasePopup {
  id: root

  anchorOffsetX: triggerItem ? Math.round((triggerItem.width - implicitWidth) / 2) : 0
  anchorOffsetY: shellParentWindow ? shellParentWindow.height - triggerItem.height + 11 : 11
  popupContent: Component {
    BarPopup {
      active: root.visible
      pinned: root.pinned
    }
  }
}
