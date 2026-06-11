//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark
import Quickshell
import "." as Square
import "clipboard" as Clipboard
import "keybinds" as Keybinds

Scope {
  Osd {}
  Square.NotificationPopups {}
  Square.NotificationCenter {}
  Bar {}
  Keybinds.KeybindOverlay {}
  Clipboard.ClipboardHistory {}
}
