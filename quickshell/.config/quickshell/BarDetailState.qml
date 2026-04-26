pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: root

  // 0 = compact, 1 = normal (default), 2 = detailed, 3 = max
  property int level: 1
  readonly property int minLevel: 0
  readonly property int maxLevel: 3

  function more() { if (level < maxLevel) level += 1 }
  function less() { if (level > minLevel) level -= 1 }
}
