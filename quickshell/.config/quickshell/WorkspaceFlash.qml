import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Scope {
  id: root

  property bool visible: WorkspaceFlashState.visible

  Timer {
    id: hideTimer
    interval: 800
    repeat: false
    onTriggered: WorkspaceFlashState.hide()
  }

  Connections {
    target: WorkspaceFlashState
    function onRevisionChanged() {
      hideTimer.restart()
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: flashWindow
      required property var modelData
      readonly property bool isTarget: WorkspaceFlashState.monitor === ""
        || (modelData && modelData.name === WorkspaceFlashState.monitor)

      screen: modelData
      WlrLayershell.namespace: "quickshell-wsflash-" + (modelData ? modelData.name : "default")
      WlrLayershell.layer: WlrLayer.Overlay
      color: "transparent"
      exclusiveZone: 0
      visible: isTarget && (root.visible || fadeAnim.running)

      anchors {
        top: true
        left: true
        right: true
      }

      margins {
        top: Theme.barHeight + 10
      }

      implicitHeight: flashCard.implicitHeight

      Rectangle {
        id: flashCard
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: Math.max(48, label.implicitWidth + Theme.padLg * 2)
        implicitHeight: 40
        radius: 0
        color: Theme.surface
        border.width: Theme.stripe
        border.color: Theme.border
        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1.0 : 0.94

        Behavior on opacity {
          NumberAnimation {
            id: fadeAnim
            duration: 140
            easing.type: Easing.OutQuad
          }
        }

        Behavior on scale {
          NumberAnimation {
            duration: 140
            easing.type: Easing.OutQuad
          }
        }

        Text {
          id: label
          anchors.centerIn: parent
          text: WorkspaceFlashState.text
          color: Theme.accentAlt
          font.family: Theme.fontFamily
          font.pixelSize: 22
          font.bold: true
        }
      }
    }
  }

  IpcHandler {
    target: "workspaceflash"

    function show(num: string, monitor: string): void {
      WorkspaceFlashState.show(num, monitor)
    }

    function hide(): void {
      WorkspaceFlashState.hide()
    }
  }
}
