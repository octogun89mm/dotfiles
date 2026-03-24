#!/usr/bin/env bash

set -euo pipefail

QS_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell"
MODE_FILE="$QS_STATE_DIR/bar-mode"
HYPR_MODE_DIR="$HOME/.dotfiles/hyprland/.config/hypr/generated"
HYPR_MODE_CONF="$HYPR_MODE_DIR/bar-mode.conf"

mkdir -p "$QS_STATE_DIR" "$HYPR_MODE_DIR"

mode="simple"
if [ -f "$MODE_FILE" ]; then
    mode=$(tr '[:upper:]' '[:lower:]' < "$MODE_FILE")
fi

case "$mode" in
    floaty)
        cat > "$HYPR_MODE_CONF" <<'EOF'
# floaty mode
EOF
        ;;
    *)
        mode="simple"
        printf '%s\n' "$mode" > "$MODE_FILE"
        cat > "$HYPR_MODE_CONF" <<'EOF'
# simple mode smart gaps and borders
workspace = w[tv1]s[false], gapsout:0, gapsin:0, bordersize:0, border:false, rounding:false, shadow:false
workspace = f[1]s[false], gapsout:0, gapsin:0, bordersize:0, border:false, rounding:false, shadow:false
EOF
        ;;
esac

if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
fi
