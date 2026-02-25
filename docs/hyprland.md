# Hyprland Setup (NixOS + Home Manager)

This repo configures Hyprland via NixOS modules and writes the runtime config via Home Manager.

## Where the config lives

- Enable Hyprland + portals + base tools: `system/desktops/hyprland.nix`
- Hyprland config source (written to `~/.config/hypr/hyprland.conf`): `users/felipe/home-modules/hypr-basic.nix`
- Waybar config + CSS (written to `~/.config/waybar/`): `system/applications/waybar.nix`
- Rofi config + scripts: `system/applications/rofi.nix`, `system/applications/rofi/`
- Notifications (SwayNC) config + CSS: `system/applications/swaync.nix`, `system/applications/swaync/`
- Helper scripts: `system/scripts/`

## Session startup (Hyprland)

Started via `exec-once` in `users/felipe/home-modules/hypr-basic.nix`:

- Bar: `waybar`
- Notifications: `swaync` (toggle with `Super+N`)
- Bluetooth tray applet: `blueman-applet`
- Cursor theme/size: `hyprctl setcursor Bibata-Modern-Ice 16`
- Clipboard history daemon: `wl-paste --watch cliphist store`

## Display layout

Configured in `users/felipe/home-modules/hypr-basic.nix`:

- Monitors: external `DP-1` at `0x0`, laptop `eDP-1` on `auto` placement.
- Workspaces pinned:
  - `1–9` → `DP-1` (workspace 1 is the default on that monitor)
  - `10` (shown as `0` in bindings/Waybar) → `eDP-1`

If your monitor names differ, check `hyprctl monitors` and update the `monitor=` / `workspace=` lines.

## UI components

- **Waybar**: floating “pill” style, modules for workspaces/clock/tray/network/bluetooth/audio/cpu/battery/power-profile (`system/applications/waybar.nix`).
- **SwayNC**: themed control-center + floating notifications (`system/applications/swaync/style.css`, `system/applications/swaync/config.json`).
  - Reload CSS without restarting: `swaync-client -rs`
- **Wallpaper**: `swww` + `%h/.local/bin/wallpaper-randomize` (prefers `~/Pictures/Wallpapers` or `~/Pictures/BingWallpaper`, fallback to NixOS Catppuccin wallpapers).
- **Hyprland visuals**:
  - Inactive-window opacity: `decoration.inactive_opacity` in `users/felipe/home-modules/hypr-basic.nix`
  - Hyprland logo + splash enabled (`misc.disable_hyprland_logo = false`, `misc.disable_splash_rendering = false`)

## Tools integrated with Hyprland

- Terminal: `kitty` (starts `tmux` by default)
- Launcher/switcher: `rofi` (drun/window/emoji/filebrowser/system-actions)
  - Wrapper: `system/applications/rofi/rofi-wrapper.sh`
  - System menu: `system/applications/rofi/system-actions.sh` (includes screenshot/lock/suspend/etc.)
- File manager: `dolphin` (default `$filemanager`, bound to `Super+E`)
- Clipboard: `wl-clipboard` + `cliphist`
  - Picker: `system/scripts/cliphist-rofi.sh` (bound to `Alt+V`)
  - Cycle: `system/scripts/cliphist-cycle.sh` (bound to `Alt+C` / `Alt+Shift+C`)
- Screenshots:
  - Quick binds: `Print` (region) and `Shift+Print` (fullscreen) via `grim` + `slurp` + `wl-copy`
  - Annotated screenshots via the system-actions menu using `satty`
- Audio:
  - Keybinds use `wpctl` (PipeWire)
  - GUI: `pavucontrol` (Waybar click)
  - Toggle mute: `pamixer -t` (Waybar right-click)
- Brightness:
  - Laptop backlight: `brightnessctl` (XF86 brightness keys)
  - Multi-monitor layout GUI: `wdisplays`
  - External monitor brightness GUI: `ddcui` (DDC/CI)
- Display mode cycling (GNOME-like Super+P): `system/scripts/toggle-displays.sh` (bound to `Super+P`)
- Power profiles: `powerprofilesctl` (bound to `Super+Alt+1/2/3`, plus Waybar status/module)
- Theme toggle helper: `system/scripts/toggle-theme` (updates GNOME/Kitty/Rofi and sets a solid Hyprland background via `swaybg`)

## Shortcuts

See `docs/hyprland-shortcuts.md`.
