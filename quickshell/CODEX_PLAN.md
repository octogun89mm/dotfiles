# Codex Plan: Fix Workspace Layout Not Updating

## Problem

After clicking the layout indicator to cycle layouts (Master -> Dwindle ->
Scrolling etc.), the bar icon doesn't update promptly. It can take up to 10
seconds because `POLL_SECONDS` was increased from 2 to 10.

Hyprland does NOT emit a socket2 event for `tiledLayout` changes on a
workspace, so the socket listener never fires for layout cycles. The script
falls back to the poll timer, which is now 10 seconds.

## Root Cause

`scripts/bar_layout.sh` line 11: `POLL_SECONDS=10`

The poll is the ONLY mechanism that detects layout changes triggered by
`cycle-layout.sh`. The socket2 events (`workspace>>`, `focusedmon>>`, etc.)
only fire when switching workspaces or monitors, not when the layout changes
within the current workspace.

## Fix

Two-part fix:

### Part A: Reduce poll interval back to 3 seconds

**File:** `.config/quickshell/scripts/bar_layout.sh`

Change line 11:
```sh
# BEFORE:
POLL_SECONDS=10

# AFTER:
POLL_SECONDS=3
```

3 seconds is a good balance -- fast enough to feel responsive after a layout
cycle, cheap enough to not waste CPU (it's just two `hyprctl` calls via jq).

### Part B: Trigger an immediate refresh after cycling layout

**File:** `.config/quickshell/LayoutIndicator.qml`

The `cycleProcess` has no `onExited` handler. After the cycle script finishes,
the layout has changed but we wait for the next poll. Instead, write "RELOAD"
to the FIFO immediately after the cycle script exits to trigger an instant
refresh.

```qml
// BEFORE (line 116-118):
Process {
  id: cycleProcess
}

// AFTER:
Process {
  id: cycleProcess
  onExited: {
    reloadProcess.exec(["/bin/sh", "-c",
      "echo RELOAD > \"" + Quickshell.env("XDG_RUNTIME_DIR") +
      "/quickshell-layout-pipe-" + root.monitorName.replace(/[^a-zA-Z0-9_-]/g, "_") + "\""
    ])
  }
}

Process {
  id: reloadProcess
}
```

This sends a RELOAD signal through the same FIFO the script reads, so
`get_layout` runs immediately and the bar updates within milliseconds of
clicking.

## Verification

1. Restart quickshell
2. Click the layout indicator to cycle layouts
3. The icon/color should update instantly (not after 3+ seconds)
4. Switch workspaces -- layout should still update correctly via socket events
5. Wait idle for 3 seconds -- poll should still work as a fallback

## Rules

- Sharp corners only. Never add border-radius.
- Colors from `wallust.js` only.
- Unix (LF) line endings.
