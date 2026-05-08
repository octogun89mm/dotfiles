# Changelog

All notable changes to these dotfiles are documented here. The format roughly
follows [Keep a Changelog](https://keepachangelog.com/) and the project loosely
honours [Semantic Versioning](https://semver.org/) (`MAJOR.MINOR.PATCH`):

- **MAJOR** — breaking layout changes that require manual migration.
- **MINOR** — new packages or user-visible features.
- **PATCH** — fixes, small tweaks, lockfile bumps.

## [0.1.0] - 2026-05-08

First tagged release. Captures the move to a Quickshell-driven desktop and a
lot of recent UX work.

### Added
- **quickshell** suspend toggle (indicator + quick action) wired to a new
  `~/.config/hypr/scripts/hypridle-suspend.sh` wrapper that disables the
  hypridle auto-suspend listener when toggled off.
- **quickshell** TTS engine picker overlay and `qs ipc`-based `speak.sh`
  (moved out of `rofi`) to choose between Kokoro / Orpheus / Gemini variants.
- **quickshell** passive model status indicator backed by
  `scripts/model-status.sh`, replacing the previous `llama-toggle` chip.
- **quickshell** wallpaper mode for the theme picker, plus
  `scripts/theme-apply.sh` and `scripts/wallpaper-apply.sh` helpers, a
  `fruitager-light` Wallust colorscheme and matching quick action.
- **quickshell** shared `WindowIcons` singleton consumed by both the workspace
  chips and the symbolic tray, with patterns for ~50 common apps.

### Changed
- **quickshell** SimpleBar layout reworked: workspace chips now show per-window
  icons with counts, the tray is rendered inline as symbolic glyphs, and the
  language indicator gained a theme/wallpaper mode toggle. Stripe accents on
  Mic/Idle/Vpn/Media chips were dropped for a flatter look.
- **quickshell** Hyprland event subscriptions are now filtered by event name to
  avoid unnecessary refreshes.
- **quickshell** Wallust template clamps low-contrast surface/border/text
  colors so themes with too-similar shades stay readable.
- **hyprland** hyprlock uses a solid background and disabled animations for
  instant render; auto-suspend timeout extended to one hour and routed through
  the new toggle script.
- **tmux** status bar palette toned down, tip dashes removed.
- **foot** switched to a monochrome teal palette.

### Fixed
- **quickshell** `mic-in-use.sh` no longer treats `cava` / `parec` / `pacat`
  monitor streams as active microphone consumers.
- **quickshell** Electron apps (Discord, Slack, Element, …) match before the
  generic `chromium` browser pattern in the icon catalog.

### Removed
- **quickshell** `LlmChip` / `LlmState` / `LlmToggle` (replaced by
  `ModelIndicator` / `ModelState`).
- **hyprland** explicit `hypridle` `exec-once` and `Mod+Shift+I` LLM toggle
  binding.
