# sway-rpi

Small Sway setup for a Raspberry Pi.

This repo is intentionally separate from the main desktop dotfiles. It keeps the
Pi config light: Sway, Ironbar, Foot, Rofi, swayidle, swaylock, and a couple of
small helper scripts.

## Install On The Pi

On the Pi:

```sh
sudo apt update
sudo apt install sway swaybg swayidle swaylock ironbar gtk4 gtk4-layer-shell foot rofi grim slurp wl-clipboard mako-notifier stow
git clone <dotfiles-repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh sway-rpi ironbar-rpi
```

Log out, then start Sway from a TTY:

```sh
sway
```

## Layout

The root dotfiles installer uses GNU Stow. `./install.sh sway-rpi` symlinks:

- `.config/sway/config`
- `.config/foot/foot.ini`
- `.local/bin/pi-screenshot`
- `.local/bin/pi-power-menu`

`./install.sh ironbar-rpi` symlinks:

- `.config/ironbar/config.toml`
- `.config/ironbar/style.css`
- `.config/ironbar/scripts/*`

## Useful Keys

- `Mod+Return`: terminal
- `Mod+d`: launcher
- `Mod+w`: browser
- `Mod+Shift+s`: area screenshot
- `Mod+q`: close window
- `Mod+Shift+c`: reload Sway
- `Mod+Ctrl+Shift+/`: reload Ironbar
- `Mod+Shift+q`: power menu
- `Mod+1..0`: workspaces
- `Mod+Shift+1..0`: move window to workspace

`Mod` is the Super key.

## Waybar Rollback

The old Waybar package is not removed. To roll back, restore the `bar {
swaybar_command waybar }` block in `.config/sway/config`, change the Ironbar
reload binding back to `killall -SIGUSR2 waybar`, then run:

```sh
cd ~/dotfiles
./install.sh sway-rpi waybar
```
