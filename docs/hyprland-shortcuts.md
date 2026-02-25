# Hyprland Shortcuts

Quick reference for the custom Hyprland bindings in `users/felipe/home-modules/hypr-basic.nix`.

## Workspace layout
- External display (`DP-1`): workspaces `1–9` (workspace 1 default on this monitor).
- Laptop display (`eDP-1`): workspace `10` (a.k.a. `0` in bindings) defaults here.

## Launchers and menus
- `Super+Enter` — Terminal (`kitty`).
- `Super+D` — App launcher (rofi drun).
- `Super+E` — File manager (`dolphin`).
- `Super+N` — Notification center (toggle SwayNC).
- `Alt+W` — Window switcher (rofi window).
- `Alt+N` — App launcher (rofi wrapper).
- `Alt+E` — Emoji picker (rofi).
- `Alt+F` — File browser (rofi filebrowser).
- `Alt+S` — System actions menu (rofi).
- `Alt+T` — Translate (rofi prompt, smart EN↔ES).
- `Alt+Shift+T` — Translate selection/clipboard (smart EN↔ES).

## Clipboard
- `Alt+V` — Clipboard picker (cliphist rofi).
- `Alt+C` / `Alt+Shift+C` — Next / previous clipboard entry.

## Session / window state
- `Super+Q` — Close focused window.
- `Super+Shift+Q` — Exit Hyprland.
- `Super+F` — Toggle fullscreen.
- `Super+V` — Toggle floating.

## Workspace navigation
- `Super+Tab` — Last workspace.
- `Super+1…9` / `Super+0` — Switch to workspace 1–10 (0 targets 10).
- `Super+Shift+H` / `Super+Shift+L` — Move focused window to previous / next workspace.
- `Super+Shift+1…9` / `Super+Shift+0` — Move focused window to workspace 1–10.

## Monitors
- `Super+Ctrl+H` / `Super+Ctrl+L` — Focus previous / next monitor.
- `Super+Ctrl+Shift+H` / `Super+Ctrl+Shift+L` — Move focused window to previous / next monitor.
- `Super+P` — Cycle display layout (extend/internal/external/mirror).
- `Super+Shift+P` — Re-pin workspaces (1–9 external, 10 laptop).

## Focus and resizing
- `Super+H` / `Super+L` — Move focus left / right.
- `Super+K` / `Super+J` — Move focus up / down.
- `Super+Ctrl+ArrowKeys` — Resize window (Left/Right = width, Up/Down = height).

## Audio and power
- `XF86AudioRaiseVolume` / `XF86AudioLowerVolume` — Volume ±5%.
- `XF86AudioMute` — Toggle mute.
- `Super+Alt+1/2/3` — Power saver / balanced / performance.

## Brightness
- `XF86MonBrightnessUp` / `XF86MonBrightnessDown` — Brightness ±5%.

## Screenshots
- `Print` — Select region to screenshot (grim + slurp, also copies to clipboard).
- `Shift+Print` — Fullscreen screenshot (also copies to clipboard).
