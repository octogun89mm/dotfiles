# Plan: Rust Quickshell Script Rewrite

## Goal

Rewrite all shell scripts in `quickshell/` and `hyprland/` to Rust binaries, and create a Pi Coding Agent extension that delegates small tasks to the local llama-server model (gemma4-e4b-it on port 3002).

---

## Phase 1: Pi Coding Agent Extension — Local Model Delegation Tool

**Why:** A custom pi tool lets the coding agent offload cheap/small tasks (e.g., "summarize this", "is this valid JSON?", "extract the function name") to the local model instead of burning expensive API tokens.

**What:**
- Create `~/.pi/agent/extensions/local-llama.ts`
- Register tool `delegate_to_local` that:
  - Takes `prompt: string` and optional `system_prompt: string`
  - Hits `http://127.0.0.1:3002/v1/chat/completions` (OpenAI-compatible)
  - Uses the `gemma4-e4b-it` model
  - Returns the response text
  - Default system: "You are a helpful coding assistant. Be concise and precise."

**Files:**
- `~/.pi/agent/extensions/local-llama.ts`

**Status:** ✅ Done (see below)

---

## Phase 2: Rust Binary Framework

**Layout:** A single Cargo workspace at `~/.dotfiles/rust-tools/` with individual binary crates.

```
rust-tools/
├── Cargo.toml          # workspace root
├── Cargo.lock
├── system-metrics/      # replaces system-metrics.sh
├── cava-mic/            # replaces cava-mic.sh
├── bar-window-count/    # replaces bar_window_count.sh + bar_layout.sh
├── disk-usage/          # replaces disk-usage.sh
├── mic-in-use/          # replaces mic-in-use.sh
├── model-status/        # replaces model-status.sh
├── speak-tts/           # replaces speak.sh
├── theme-apply/         # replaces theme-apply.sh
├── wallpaper-apply/     # replaces wallpaper-apply.sh
├── quickshell-restart/  # replaces restart.sh
├── waveform/            # replaces waveform.sh
├── cycle-layout/        # replaces cycle-layout.sh
├── cycle-sink/          # replaces cycle-sink.sh
├── hypridle-suspend/    # replaces hypridle-suspend.sh
├── rofi-apps/           # replaces rofi-apps.sh
├── rofi-tools/          # replaces rofi-tools.sh
├── tts-selection/       # replaces tts-selection.sh
└── wsflash/             # replaces wsflash.sh
```

**Dependencies (shared across crates):**
- `serde` / `serde_json` — JSON output
- `reqwest` — HTTP (for model-status, speak)
- Any Hyprland IPC: use `std::process::Command` to call `hyprctl` (simpler and reliable)

---

## Phase 3: Binary-by-Binary Plan

### 3.1 — `system-metrics`
**Replaces:** `system-metrics.sh`

**Source of truth:** `/proc/stat`, `/proc/loadavg`, `/proc/meminfo`, `sensors` command, optional GPU via `nvidia-smi` or `cat /sys/class/drm/*/device/gpu_busy_percent`.

**Output:** Single JSON line:
```json
{
  "cpu": 45.2,
  "cpu_temp": "65.0°C",
  "load1": 2.5,
  "gpu": 30,
  "gpu_temp": "70°C",
  "gpu_vram_used": 2048,
  "gpu_vram_total": 8192,
  "mem_used": 8.2,
  "mem_total": 31.4
}
```

**Implementation:** Read `/proc/stat` twice (with 200ms delay) for delta-based CPU%. Parse `/proc/meminfo` directly. Use `sensors -j` or read thermal files for temp.

### 3.2 — `bar-window-count`
**Replaces:** `bar_window_count.sh` + `bar_layout.sh`

**Input:** Arg `$1` = monitor name, or env `MONITOR_NAME`.

**Output:** Single JSON line:
```json
{"count":3,"layout":"MASTER"}
```

**Implementation:** Call `hyprctl monitors -j` and `hyprctl workspaces -j`, parse JSON.

### 3.3 — `disk-usage`
**Replaces:** `disk-usage.sh`

**Output:** JSON array of mount info:
```json
[{"mount":"/","label":"ROOT","used":"8.2","total":"31.4"}]
```

**Implementation:** Use `nix::sys::statvfs` or parse `df -BG` output.

### 3.4 — `mic-in-use`
**Replaces:** `mic-in-use.sh`

**Output:** JSON:
```json
{"active":false,"apps":[]}
```

**Implementation:** Call `pactl -f json list sources` and `pactl -f json list source-outputs`, parse, filter out cava/parec/pacat.

### 3.5 — `model-status`
**Replaces:** `model-status.sh`

**Output:** JSON:
```json
{"loaded":true,"icon":"󰧑","tooltip":"llama.cpp loaded: gemma4-e4b-it"}
```

**Implementation:** Check `/proc` for `llama-server` processes, parse args for `--alias` or model path.

### 3.6 — `cava-mic`
**Replaces:** `cava-mic.sh`

**What it does:** Writes a temp cava config that captures from the default PulseAudio source, outputs raw ASCII bars.

**Implementation:** Write a temp config to disk, exec `cava -p <config>`. This one is thin — can stay as a Rust binary that just writes the config and execs cava, or stay as a shell script. **Decision:** keep as shell script since it's just a thin config writer + exec. Not worth rewriting.

### 3.7 — `waveform`
**Replaces:** `waveform.sh`

**What it does:** Uses `parec` (PulseAudio capture from default sink monitor), pipes raw PCM samples through a small Python script that prints envelope frames.

**Rust implementation:** 
- Spawn `parec --format=s16le --rate=8000 --channels=1 -d "${sink}.monitor" --raw`
- Read raw PCM from stdin, compute signed mean and peak amplitude per chunk
- Print `avg;peak` lines at ~60Hz

**Dependencies:** `std::process::Command` for `pactl` + `parec`. No external crates needed beyond std.

### 3.8 — `speak-tts`
**Replaces:** `speak.sh`

**What it does:** Lists wav files from cache dir, shows them in rofi dmenu, plays selected or opens new TTS input via quickshell IPC.

**Implementation:** Rust binary with rofi subprocess.

### 3.9 — `theme-apply`
**Replaces:** `theme-apply.sh`

**What it does:** Runs `wallust cs <theme>` or `wallust theme <theme>` depending on input, updates cache files, reloads hyprland/kitty/dunst, restarts quickshell.

**Implementation:** Use `std::process::Command` for each step. Parse theme name for light/dark detection.

### 3.10 — `wallpaper-apply`
**Replaces:** `wallpaper-apply.sh`

**What it does:** Preloads wallpaper via `hyprctl hyprpaper`, writes hyprpaper.conf, runs `wallust run`, updates cache files, notifies.

**Implementation:** Rust binary with subprocess calls.

### 3.11 — `quickshell-restart`
**Replaces:** `restart.sh`

**What it does:** Finds quickshell PIDs by config path, kills them, waits for exit, execs launch.sh.

**Implementation:** Rust binary.

### 3.12 — `cycle-layout`
**Replaces:** `cycle-layout.sh`

**What it does:** Cycle through master/dwindle/scrolling/monocle for focused workspace.

**Implementation:** Call `hyprctl activeworkspace -j`, parse, cycle, `hyprctl keyword workspace ...`.

### 3.13 — `cycle-sink`
**Replaces:** `cycle-sink.sh`

**What it does:** Cycle audio sinks, move all sink-inputs, notify.

**Implementation:** Use `pactl` subprocesses via Rust, then `notify-send`.

### 3.14 — `hypridle-suspend`
**Replaces:** `hypridle-suspend.sh`

**What it does:** Toggle/status/suspend with a state file.

**Implementation:** Rust binary using state file at `$XDG_STATE_HOME/hypridle-suspend-disabled`.

### 3.15 — `rofi-apps`
**Replaces:** `rofi-apps.sh`

**What it does:** Rofi menu with app launcher, terminal, browser, etc.

**Implementation:** Rust binary calling `rofi -dmenu`.

### 3.16 — `rofi-tools`
**Replaces:** `rofi-tools.sh`

**What it does:** Rofi menu with screenshot, clipboard, emoji, etc.

**Implementation:** Rust binary calling `rofi -dmenu`.

### 3.17 — `tts-selection`
**Replaces:** `tts-selection.sh`

**What it does:** Get selected text via `wl-paste`, pipe to kokoro-tts.

**Implementation:** Rust binary.

### 3.18 — `wsflash`
**Replaces:** `wsflash.sh`

**What it does:** Tracks before/after workspace changes, calls quickshell IPC for flash.

**Implementation:** Rust binary calling `hyprctl dispatcher` and `qs ipc`.

---

## Phase 4: Wiring Changes

For each Rust binary, the QML State files (`*State.qml`) need to have their `scriptPath` updated and the `Process { command: [ ... ] }` updated from running a shell script to running the compiled binary.

### Example change in `MetricsState.qml`:
```
-  readonly property string scriptPath: home + "/.dotfiles/quickshell/.config/quickshell/scripts/system-metrics.sh"
+  readonly property string scriptPath: home + "/.dotfiles/rust-tools/target/release/system-metrics"
```

---

## Phase 5: Build System

- `Cargo.toml` workspace at `~/.dotfiles/rust-tools/`
- All binaries share common utilities crate for JSON output, hyprctl wrappers, etc.
- Add to `~/.dotfiles/` workspace (no top-level build needed; each binary can be built independently)
- Build with `cargo build --release` from the `rust-tools/` directory

---

## Execution Order

1. ~~Write this plan~~ ✅
2. Create Pi Coding Agent extension for local model delegation
3. Create Cargo workspace structure
4. Implement each binary (start with system-metrics, then the hyprctl-heavy ones)
5. Update QML State files to point to new binaries
6. Build and test
