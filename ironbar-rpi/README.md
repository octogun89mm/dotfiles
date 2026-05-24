# ironbar-rpi

Ironbar package for the Raspberry Pi Sway setup. It installs
`~/.config/ironbar/config.toml`, `style.css`, and small helper scripts for the
Pi-specific Bluetooth speaker, volume, disk, and network widgets.

## Dependencies

On Debian/Raspberry Pi OS, install Ironbar and the GTK layer shell runtime from
the package source you use for Wayland tools. Package names vary by release, but
the required pieces are:

- `ironbar`
- `gtk4`
- `gtk4-layer-shell`
- `upower` for the battery widget, if the device has a battery
- `network-manager`, `wireplumber`, and `pulseaudio-utils` or compatible tools
  for the helper scripts

## Install

```sh
cd ~/dotfiles
./install.sh ironbar-rpi
./install.sh sway-rpi
```

Reload Sway with `Mod+Shift+o`, or log out and start Sway again from a TTY:

```sh
sway
```

The Pi Sway config starts Ironbar directly from Sway with `exec_always`.
`Mod+Ctrl+Shift+/` runs `ironbar reload` for config and CSS reloads.

## Rollback

The Waybar files are left untouched. To roll back, restore the Waybar bar block
in `sway-rpi/.config/sway/config`, change the reload binding back to the Waybar
signal command, then reinstall the Sway and Waybar packages you want:

```sh
cd ~/dotfiles
./install.sh sway-rpi waybar
```
