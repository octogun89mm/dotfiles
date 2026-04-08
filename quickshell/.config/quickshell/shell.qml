//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark
import Quickshell
import "clipboard" as Clipboard
import "keybinds" as Keybinds
import "notifications" as Notif

Scope {
  Osd {}
  Keybinds.KeybindOverlay {}
  Clipboard.ClipboardHistory {}
  Notif.NotificationPopup {}
  Notif.NotificationCenter {}
  Bar {}
}
