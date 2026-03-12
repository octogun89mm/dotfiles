# Dotfiles

My dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Packages

| Package | Description |
|---------|-------------|
| **hyprland** | Hyprland compositor config, hypridle, helper scripts, layout cycling, keyboard layout notifications, plus a local-only hyprpaper template |
| **quickshell** | Current top bar and popup shell for Hyprland, with workspaces, tray, audio, VPN, idle inhibitor, weather, system stats, and calendar popup |
| **eww** | Legacy bar config and helper scripts still kept in-repo for migration reuse |
| **rofi** | App launcher, screenshot/screenrecord/OCR/wallpaper/emoji picker scripts |
| **waybar** | Secondary bar config and utility scripts reused by other packages |
| **sway** | Sway compositor config (legacy) |
| **tmux** | Terminal multiplexer config |
| **nvim** | Lazy.nvim-based Neovim config with LSP, completion, Telescope, git tooling, AI helpers, and focused editing UX |

## Current State

The main bar work has moved to `quickshell`, and `eww` is now retained mostly as a source of scripts and reference modules during the migration.

The Quickshell config is modular and currently includes:

- multi-monitor bar windows
- Hyprland workspace chips, including special workspaces
- centered clock popup with quick actions, weather, and system metrics
- date-triggered calendar popup with pin support
- tray, sound, VPN, idle inhibitor, and keyboard layout indicators
- Wallust-driven colors via `wallust.js`

The Neovim config currently includes:

- `lazy.nvim` plugin management with a small modular Lua layout
- LSP via Mason and `nvim-lspconfig` for Lua, Python, JSON, HTML, QML, and CSS, including a separate GTK CSS flow for Waybar files
- completion with `nvim-cmp`, LuaSnip, path/buffer sources, and command-line completion
- Treesitter highlighting and indentation for the main languages used in this repo
- Telescope file finding, buffer switching, and file-browser picker
- git workflow support through Neogit and Gitsigns
- AI-assisted editing through CodeCompanion chat/inline actions and Minuet inline completion against a local `llama.cpp` endpoint
- `which-key` leader menus, Zen Mode, multi-cursor editing, indent guides, color previews, persistent undo, and a global `lualine` statusline

## Screenshots

Screenshots are intentionally kept out of git because they can capture personal information from the local desktop session.
