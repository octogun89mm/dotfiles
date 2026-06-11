pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications as Notify

Singleton {
  id: root

  property bool dnd: false
  property bool centerVisible: false
  property string centerScreenName: ""
  property var notificationMap: ({})
  readonly property alias history: historyModel
  readonly property alias popupQueue: popupQueueModel
  readonly property int unreadCount: historyModel.count
  property int criticalCount: 0
  readonly property int timeoutMs: 10000

  function nowMs() {
    return Date.now()
  }

  function notificationById(notificationId) {
    return notificationMap[notificationId] || null
  }

  function isCritical(notification) {
    return notification && notification.urgency === Notify.NotificationUrgency.Critical
  }

  function indexForId(model, notificationId) {
    for (let i = 0; i < model.count; i++) {
      if (model.get(i).notificationId === notificationId) return i
    }
    return -1
  }

  function recalcCriticalCount() {
    let next = 0
    for (let i = 0; i < historyModel.count; i++) {
      if (isCritical(notificationById(historyModel.get(i).notificationId))) next += 1
    }
    criticalCount = next
  }

  function removePopupById(notificationId) {
    const index = indexForId(popupQueueModel, notificationId)
    if (index !== -1) popupQueueModel.remove(index)
  }

  function removeById(notificationId) {
    const historyIndex = indexForId(historyModel, notificationId)
    if (historyIndex !== -1) historyModel.remove(historyIndex)
    removePopupById(notificationId)

    const next = Object.assign({}, notificationMap)
    delete next[notificationId]
    notificationMap = next

    recalcCriticalCount()
  }

  function registerNotification(notification) {
    if (!notification) return

    notification.tracked = true
    removeById(notification.id)

    const next = Object.assign({}, notificationMap)
    next[notification.id] = notification
    notificationMap = next

    const timestamp = Math.floor(nowMs() / 1000)
    historyModel.insert(0, {
      notificationId: notification.id,
      timestamp: timestamp
    })

    if (!dnd) {
      popupQueueModel.insert(0, {
        notificationId: notification.id,
        timestamp: timestamp,
        expiresAt: nowMs() + timeoutMs
      })
    }

    while (popupQueueModel.count > 4) {
      popupQueueModel.remove(popupQueueModel.count - 1)
    }

    recalcCriticalCount()

    notification.closed.connect(function() {
      root.removeById(notification.id)
    })
  }

  function dismissOne(notification) {
    if (!notification) return
    notification.dismiss()
    removeById(notification.id)
  }

  function clearAll() {
    const ids = []
    for (let i = 0; i < historyModel.count; i++) {
      ids.push(historyModel.get(i).notificationId)
    }

    for (let i = 0; i < ids.length; i++) {
      const notification = notificationById(ids[i])
      if (notification) notification.dismiss()
    }

    historyModel.clear()
    popupQueueModel.clear()
    notificationMap = ({})
    criticalCount = 0
  }

  function toggleDnd() {
    dnd = !dnd
    if (dnd) popupQueueModel.clear()
  }

  function toggleCenter(screenName) {
    const target = screenName || ""
    if (centerVisible && centerScreenName === target) {
      centerVisible = false
      centerScreenName = ""
      return
    }

    centerScreenName = target
    centerVisible = true
  }

  function invokeDefault(notification) {
    if (!notification || !notification.actions) return

    for (let i = 0; i < notification.actions.length; i++) {
      const action = notification.actions[i]
      if (action.identifier === "default") {
        action.invoke()
        return
      }
    }
  }

  Notify.NotificationServer {
    keepOnReload: true
    bodySupported: true
    bodyMarkupSupported: true
    actionsSupported: true
    imageSupported: true
    persistenceSupported: true

    onNotification: function(notification) {
      root.registerNotification(notification)
    }
  }

  ListModel {
    id: historyModel
    dynamicRoles: true
  }

  ListModel {
    id: popupQueueModel
    dynamicRoles: true
  }

  Timer {
    interval: 500
    running: popupQueueModel.count > 0
    repeat: true
    onTriggered: {
      const current = root.nowMs()
      for (let i = popupQueueModel.count - 1; i >= 0; i--) {
        const entry = popupQueueModel.get(i)
        if (entry.expiresAt <= current) root.removePopupById(entry.notificationId)
      }
    }
  }
}
