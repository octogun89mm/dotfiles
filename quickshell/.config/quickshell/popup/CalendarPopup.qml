import QtQuick

BasePopup {
  id: root

  anchorOffsetX: triggerItem ? triggerItem.width - implicitWidth : 0
  anchorOffsetY: 10
  popupContent: Component {
    CalendarBody {
      pinned: root.pinned
    }
  }
}
