# Dotfiles

My dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Packages

| Package | Description |
|---------|-------------|
| **hyprland** | Hyprland compositor config, hypridle, helper scripts, layout cycling, keyboard layout notifications, plus a local-only hyprpaper template |
| **quickshell** | Top bar, popup shell, clipboard history panel, keybind overlay, notification center, and OSD for Hyprland |
| **eww** | Legacy bar config and helper scripts still kept in-repo for migration reuse |
| **rofi** | App launcher, clipboard history fallback, screenshot/screenrecord/OCR/wallpaper/emoji picker scripts |
| **waybar** | Secondary bar config and utility scripts reused by other packages |
| **sway** | Sway compositor config (legacy) |
| **tmux** | Terminal multiplexer config |
| **nvim** | Lazy.nvim-based Neovim config with built-in treesitter, LSP, completion, Telescope, git tooling, AI helpers, and focused editing UX |

## Current State

The main bar work has moved to `quickshell`, and `eww` is now retained mostly as a source of scripts and reference modules during the migration.

The Quickshell config is modular and currently includes:

- multi-monitor bar windows
- Hyprland workspace chips, including special workspaces
- centered clock popup with quick actions, weather, and system metrics
- date-triggered calendar popup with pin support
- clipboard history panel with image/text preview, filtering, and keyboard navigation
- keybind overlay showing all Hyprland bindings on a visual keyboard layout
- notification popup and notification center
- OSD for volume, brightness, and shell state changes
- tray, sound, VPN, idle inhibitor, and keyboard layout indicators
- Wallust-driven colors via `wallust.js`

The Neovim config currently includes:

- `lazy.nvim` plugin management with a small modular Lua layout
- LSP via Mason and `nvim-lspconfig` for Lua, Python, JSON, HTML, QML, and CSS, including a separate GTK CSS flow for Waybar files
- completion with `nvim-cmp`, LuaSnip, path/buffer sources, and command-line completion
- built-in treesitter with bundled queries for Lua, Python, JSON, Vim, Vimdoc, and Markdown
- Telescope file finding, buffer switching, and file-browser picker
- git workflow support through Neogit and Gitsigns
- AI-assisted editing through CodeCompanion chat/inline actions and Minuet inline completion against a local `llama.cpp` endpoint
- `which-key` leader menus, Zen Mode, multi-cursor editing, indent guides, color previews, persistent undo, and a global `lualine` statusline

## Screenshots

Screenshots are intentionally kept out of git because they can capture personal information from the local desktop session.
