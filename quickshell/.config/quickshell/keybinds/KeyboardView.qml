import QtQuick
import "." as Keybinds
import "keyboardLayout.js" as KeyboardLayout

Column {
  id: root

  spacing: 12
  readonly property real contentWidth: 1240
  readonly property real contentHeight: 430

  Repeater {
    model: KeyboardLayout.rows

    delegate: Row {
      required property var modelData

      spacing: 10

      Repeater {
        model: modelData

        delegate: Keybinds.KeyboardKey {
          required property var modelData

          keyModel: modelData
          bindData: Keybinds.KeybindState.keyDisplayBind(modelData.id)
          modifierActive: modelData.id === "SHIFT" || modelData.id === "SHIFT_R"
            ? Keybinds.KeybindState.modifierActive("SHIFT")
            : modelData.id === "CTRL"
              ? Keybinds.KeybindState.modifierActive("CTRL")
              : modelData.id === "ALT" || modelData.id === "ALT_R"
                ? Keybinds.KeybindState.modifierActive("ALT")
                : modelData.id === "SUPER" || modelData.id === "SUPER_R"
                  ? Keybinds.KeybindState.modifierActive("SUPER")
                  : false
        }
      }
    }
  }
}
