# Dotfiles

My dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Packages

| Package | Description |
|---------|-------------|
| **hyprland** | Hyprland compositor config, hypridle, helper scripts, layout cycling, keyboard layout notifications, plus a local-only hyprpaper template |
| **quickshell** | Top bar, popup shell, clipboard history panel, keybind overlay, notification center, and OSD for Hyprland |
| **eww** | Legacy bar config and helper scripts still kept in-repo for migration reuse |
| **rofi** | App launcher, clipboard history fallback, screenshot/screenrecord/OCR/wallpaper/emoji picker scripts |
| **foot** | Foot terminal config and shared Wallust color include |
| **waybar** | Secondary bar config and utility scripts reused by other packages |
| **sway** | Sway compositor config (legacy) |
| **sway-rpi** | Lightweight Raspberry Pi Sway package, excluded from default install and installed explicitly with `./install.sh sway-rpi` |
| **zsh-rpi** | Minimal Raspberry Pi zsh package without vi mode, excluded from default install and installed explicitly with `./install.sh zsh-rpi` |
| **tmux** | Terminal multiplexer config |
| **scripts** | Repo-local helper scripts such as `set-font.sh` for swapping the monospace family across configs |

## Current State

The main bar work has moved to `quickshell`, and `eww` is now retained mostly as a source of scripts and reference modules during the migration.

The current desktop stack is centered on Hyprland + Quickshell, with `Iosevka` as the shared monospace font across the launcher, bars, notifications, and terminal configs. The font family can be swapped repo-wide with `scripts/set-font.sh`.

`hyprland/.config/hypr/scripts/wake-gate.py` is used as the post-suspend wake gate and expects the Python `evdev` module to be available on the host.

The Quickshell config is modular and currently includes:

- multi-monitor bar windows
- Hyprland workspace chips with per-window glyph icons (hot-reloaded JSON catalog at `quickshell/.config/quickshell/window-icons/`, shared with the tray)
- inline symbolic tray with per-icon fallbacks for common desktop apps
- centered clock popup with quick actions, weather, and system metrics
- compact stereo spectrogram widgets flanking the centered clock
- date-triggered calendar popup with pin support
- clipboard history panel with image/text preview, filtering, and keyboard navigation
- keybind overlay showing all Hyprland bindings on a visual keyboard layout
- notification popup and notification center
- OSD for volume, brightness, and shell state changes
- tray, sound, VPN, tailscale toggle, idle inhibitor, suspend toggle, model-status, and keyboard layout indicators
- theme picker with both Wallust theme and wallpaper modes (`scripts/theme-apply.sh`, `scripts/wallpaper-apply.sh`)
- TTS engine picker overlay driving `scripts/speak.sh` over `qs ipc`
- Wallust-driven colors via `wallust.js`, with low-contrast colors auto-clamped for readability

See [CHANGELOG.md](CHANGELOG.md) for a per-release summary of changes.

The editor has moved to Emacs. The previous `lazy.nvim`-based Neovim config is archived under `legacy/nvim/` — kept in-repo for reference but no longer stowed (revive with `stow -d ~/.dotfiles/legacy -t ~ nvim`). A fresh, minimal Emacs config is being built up separately and its Wallust theme is generated to `~/.config/emacs/juju-theme.el`.

## Screenshots

Not in the repo — gitignored. Run it.
