# Quickshell Bar Notes

This package is a Stow package for the Quickshell bar config at:

- `quickshell/.config/quickshell`

## Project Direction

- This bar is replacing the old `eww` bar.
- Keep the Quickshell config modular.
- Do not collapse the bar into one giant QML file.
- Prefer small focused components and grouped subdirectories.

## Current Structure

- `shell.qml`: root entrypoint
- `Bar.qml`: top bar window composition
- `Workspace.qml` / `WorkspaceChip.qml`: Hyprland workspace module
- `Clock.qml`: centered clock chip
- `Date.qml`: right-side date
- `Tray.qml` / `TrayItem.qml`: systray
- `Vpn.qml`: bar VPN indicator
- `IdleInhibitor.qml`: bar idle inhibitor indicator
- `popup/`: popup shell and popup content modules

## Styling Rules

- Sharp corners only by default. Do not add rounded corners unless explicitly requested.
- Use `Roboto Mono` for bar text.
- Use Wallust-generated colors from `wallust.js`.
- Prefer the base16-style palette keys exposed there:
  - `base00`: bar background
  - `base01`: lighter surface / outline color
  - `base03`: muted text / inactive indicators
  - `base05`: normal foreground
  - `base0D`: accent
- Current visual language:
  - clock: filled accent chip
  - vpn / idle: outlined chips
  - workspaces: outlined when inactive, accent-filled when focused/active

## Workspace Rules

- Show occupied workspaces and also the focused workspace when empty.
- Support special workspaces.
- `special:dropdown` displays as `=`.
- `special:magic` displays as `-`.
- `special:dropdown` should sort last.
- Other `special:*` workspaces should sort after normal workspaces.

## Popup Direction

- Popup opens from hovering the centered clock.
- Left click on the clock pins/unpins the popup.
- Popup should appear centered under the clock.
- Keep the popup modular:
  - `popup/PopupShell.qml`
  - `popup/BarPopup.qml`
  - `popup/QuickActions.qml`
  - `popup/WeatherCard.qml`
  - `popup/SystemColumn.qml`
  - supporting card/action modules
- The popup should preserve the old `eww` idea:
  - quick actions/status
  - weather hero card
  - compact system stats
- But it should be cleaner and more Quickshell-like than the old row-heavy `eww` panel.

## Performance Rules

- Prioritize low-overhead data sources.
- Reuse existing optimized scripts when they already exist.
- Prefer listener/socket-based sources over polling when practical.
- Only run expensive refreshes while the popup is visible.
- Current reused sources:
  - `waybar/scripts/expressvpn.sh`
  - `waybar/scripts/idle-inhibit.sh`
  - `eww/shell/bar_volume.sh`
  - `eww/shell/bar_language.sh`
  - `eww/shell/bar_weather.sh`
  - `eww/scripts/eww-bar` for one-shot system metrics

## Wallust

- Wallust template lives at:
  - `~/.config/wallust/templates/quickshell-colors.js`
- Wallust generates:
  - `~/.config/quickshell/wallust.js`
- Quickshell should consume `wallust.js` instead of hardcoded colors wherever practical.

## Pending UX Note

- After popup work is stable, the date should get a visual pass so it matches the rest of the bar.
