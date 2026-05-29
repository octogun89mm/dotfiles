# Start the local Sway session from the tty1 autologin.
# SSH and nested terminals should remain normal shells.
if [[ -z "$DISPLAY$WAYLAND_DISPLAY" && -z "$SSH_CONNECTION" && "$(tty)" == "/dev/tty1" ]]; then
  export XDG_SESSION_TYPE=wayland
  export XDG_CURRENT_DESKTOP=sway
  export XDG_SESSION_DESKTOP=sway
  export XCURSOR_THEME=breeze_cursors
  export XCURSOR_SIZE=24
  export GTK_THEME=Arc-Dark
  export QT_QPA_PLATFORMTHEME=gtk3
  if command -v dbus-run-session >/dev/null 2>&1 && command -v sway >/dev/null 2>&1; then
    dbus-run-session sway || {
      print -u2 'sway failed to start; continuing in the shell'
    }
  fi
fi


# Added by Antigravity CLI installer
export PATH="/home/juju/.local/bin:$PATH"
