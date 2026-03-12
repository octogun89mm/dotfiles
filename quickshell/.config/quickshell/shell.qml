//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark
import Quickshell
import "notifications" as Notif

Scope {
  Osd {}
  Notif.NotificationPopup {}
  Notif.NotificationCenter {}
  Bar {}
}
