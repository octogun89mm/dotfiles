# Changelog

All notable changes to these dotfiles are documented here. The format roughly
follows [Keep a Changelog](https://keepachangelog.com/) and the project loosely
honours [Semantic Versioning](https://semver.org/) (`MAJOR.MINOR.PATCH`):

- **MAJOR** — breaking layout changes that require manual migration.
- **MINOR** — new packages or user-visible features.
- **PATCH** — fixes, small tweaks, lockfile bumps.

## [1.0.0] - 2026-06-04

### Added
- **emacs** package: minimal config themed with Gruber Darker, run as an
  always-on `emacs --fg-daemon`; `emacsclient` is now the default `$EDITOR`/`$VISUAL`.
- **qtile** package with multi-monitor support, Wallust integration, and system
  status widgets (CPU governor, Tailscale).
- **quickshell** Jubotai chat widget (status indicator + conversation popup) and
  helper scripts (Tailscale, ExpressVPN, idle-inhibit).
- **rofi** `deactivate-screens.sh` helper.

### Changed
- **nvim** archived to `legacy/nvim` (no longer stowed) — the editor has moved to Emacs.
- **waybar** archived to `legacy/waybar`; the desktop bar is now Quickshell.

### Removed
- **Raspberry Pi packages** (`sway-rpi`, `zsh-rpi`, `theme-rpi`, `ironbar-rpi`)
  relocated to a separate Pi dotfiles repo. **Breaking:** they are no longer
  installable from this repo.

## [0.2.1] - 2026-05-13

### Added
- **quickshell** CPU governor indicator for the expanded details row.
- **zsh** prompt schema contract for the custom multi-line prompt.

### Changed
- **hyprland** keeps normal gaps and borders on the 4K monitor workspaces while
  limiting single-window no-decoration rules to the side and top monitors.
- **quickshell** trims always-on cava work, moves status indicators to the left
  side of the secondary bar, and uses file URIs for local tray/notification
  icons.
- **foot** refreshes the dark terminal palette from the current Wallust colors.
- **zsh** enables persistent shared history and adds user/host to the full
  prompt.

## [0.2.0] - 2026-05-09

### Added
- **quickshell** tailscale toggle indicator with `waybar/scripts/tailscale.sh`
  helper, sitting next to the suspend toggle.
- **quickshell** `WindowIcons` is now data-driven: app/tray patterns live in
  hot-reloaded `window-icons/apps.json` + `tray.json`, and SVG glyphs in
  `window-icons/svg/` are recolored on the fly. New `helium.svg` (asterisk
  logo) replaces the previous atom glyph.
- **quickshell** cava "scope" mode wired into the spectrogram, plus a debounced
  workspace refresh and a scaffold for SVG window icons.

### Changed
- **foot** repainted dark palette with warmer foreground and accents.
- **quickshell** clipboard panel now caps at half the screen height instead of
  `screen - 20px`.
- **quickshell** mic cava framerate synced with the main cava state, and the
  suspend toggle moved next to the tray.
- **hyprland** `F16` Discord-mute bind now matches both `Vesktop` and
  `discord` window classes.

## [0.1.1] - 2026-05-08

### Changed
- **quickshell** Browsers in `WindowIcons` are split per-vendor: Helium now
  gets an atom glyph, Brave a shield, Edge/Opera/Safari/Vivaldi/qutebrowser
  their own marks, and only literal `chromium`/`chrome` keep the chrome glyph.

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
