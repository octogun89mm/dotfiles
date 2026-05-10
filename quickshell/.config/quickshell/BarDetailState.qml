pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: root

  // 0 = compact, 1 = normal (default), 2 = detailed, 3 = max
  property int level: 1
  readonly property int minLevel: 0
  readonly property int maxLevel: 3

  property int lastExpandedLevel: 1

  function setLevel(nextLevel) {
    level = Math.max(minLevel, Math.min(maxLevel, nextLevel))
    if (level > minLevel) lastExpandedLevel = level
  }

  function more() { setLevel(level + 1) }
  function less() { setLevel(level - 1) }

  function toggleCollapsed() {
    if (level === minLevel) {
      setLevel(lastExpandedLevel > minLevel ? lastExpandedLevel : 1)
    } else {
      lastExpandedLevel = level
      level = minLevel
    }
  }

  function cycleDetails() {
    if (level === minLevel) return
    setLevel(level >= maxLevel ? 1 : level + 1)
  }
}
