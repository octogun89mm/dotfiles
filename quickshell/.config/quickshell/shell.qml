//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark
import Quickshell
import "clipboard" as Clipboard
import "keybinds" as Keybinds
import "notifications" as Notif
import "popup" as Popup

Scope {
  Osd {}
  Keybinds.KeybindOverlay {}
  Clipboard.ClipboardHistory {}
  Notif.NotificationPopup {}
  Notif.NotificationCenter {}
  Popup.ThemePicker {}
  Bar {}
}
