import QtQuick

BasePopup {
  id: root

  anchorOffsetX: triggerItem ? triggerItem.width - implicitWidth : 0
  anchorOffsetY: shellParentWindow && triggerItem ? shellParentWindow.height - triggerItem.height + 11 : 11
  popupContent: Component {
    CalendarBody {
      pinned: root.pinned
    }
  }
}
