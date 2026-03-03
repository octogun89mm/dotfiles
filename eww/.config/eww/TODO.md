# Eww TODO

## Hypr listener regression

- Date: 2026-03-03
- Safe state: reverted and rebuilt, Eww running from revert commit `bebdc23`
- Problem commit: `aeff1dc` (`Fix Eww Hyprland listener lag`)

### What happened

- The targeted Hypr socket fixes were fine:
  - workspace refresh no longer triggers on `activewindow`
  - event reader handles trailing buffered data on EOF
  - reconnect delay reduced to 100ms
- The later shared `hypr_listener` refactor introduced a runtime regression under Eww:
  - `scripts/eww-bar workspaces` hit ~100% CPU
  - `scripts/eww-bar wincount 0/1` also hit ~100% CPU
  - the bar became unresponsive

### Notes for next session

- Start from the reverted working tree, not from `aeff1dc`
- Re-check the original targeted fixes separately from the shared helper refactor
- Investigate why the shared helper hot-looped only when launched by Eww
- If retrying the refactor, validate with live Eww before committing/pushing

### Follow-up from 2026-03-03

- Reapplied safely on top of the reverted tree:
  - Hypr event reader now flushes trailing buffered data on EOF
  - Hypr event reconnect delay is back to 100ms in the existing per-command listeners
  - workspaces no longer refreshes on `activewindow` / `activewindowv2`
- Shared `hypr_listener` remains intentionally reverted
  - The helper bundled two separate concerns: event socket consumption and adaptive poll scheduling
  - The regression did not need the targeted fixes; it only appeared once the shared helper was introduced
  - Best current assumption: the abstraction changed runtime behavior enough that Eww-spawned long-lived listeners ended up over-refreshing or hot-looping, while the original per-command loops stayed stable

### Architecture notes

- `scripts/eww-bar` is a single native binary with many subcommands, not a shell wrapper
- Each `deflisten` in `bar.yuck` launches a long-lived `eww-bar <subcommand>` process
- The stable model is:
  - one Hypr event thread per subcommand process
  - optional local tick thread only in commands that need adaptive polling
  - command-specific event filters kept close to query logic
- If a listener abstraction is retried later, keep it narrower:
  - do not combine event reading and tick policy in one helper
  - keep any reader state per listener instance, never shared mutable state
  - reintroduce it first for non-polling commands like `language` and `submap`

---

## Code review of current unstaged changes

- Reviewer: Claude (Opus)
- Date: 2026-03-03

### 1. `HYPR_EVENT_RECONNECT_DELAY_US` constant — Approved

Replacing `sleep(1)` with `usleep(HYPR_EVENT_RECONNECT_DELAY_US)` (100ms) across all 6 command files via a shared constant in `hypr_ipc.h` is clean. Faster reconnects, single source of truth. No issues.

### 2. `hypr_event_readline` EOF flush — Approved, minor note

The new block at `hypr_ipc.c:72-80` flushes remaining buffered data on EOF (socket closes mid-line without trailing newline). Correct fix — without it the last partial line is silently dropped.

**Minor:** The condition `rlen > rpos` on line 72 is always true at that point because compaction above already set `rpos = 0`. The real invariant being tested is `rlen > 0`. Still works correctly, but `rlen > 0` would be clearer. Not a blocker.

### 3. Removing `activewindow>>` / `activewindowv2>>` from workspaces — Needs confirmation

`cmd_workspaces.c` removes `activewindow>>` and `activewindowv2>>` from `should_refresh_on_event`. Switching the focused window within the same workspace no longer triggers a workspace refresh.

Since `query_workspaces` only tracks the active *workspace* id, not the active *window*, this looks correct — changing active window doesn't change workspace state.

**Question:** These events were also feeding `record_event()`, which keeps the tick thread in fast-poll mode (100ms). With them removed, workspace state after a window focus change relies on the 2-second idle poll. Is that acceptable, or could occupancy/visibility updates lag noticeably?

### No issues found

- All files already `#include <unistd.h>` for `usleep`.
- Constant naming is clear and well-placed.
- Changes are scoped correctly — no shared helper reintroduction.

### Follow-up question for next review

- Workspace refresh no longer treats `activewindow>>` / `activewindowv2>>` as activity.
- Current reasoning: this is correct because the workspace widget only reflects active workspace, occupancy, and visibility, none of which change on pure in-workspace focus switches.
- Open question to pressure-test:
  - Could dropping `activewindow*` still cause perceptible lag for any workspace-adjacent state because those events no longer keep the adaptive poll loop in 100ms mode?
