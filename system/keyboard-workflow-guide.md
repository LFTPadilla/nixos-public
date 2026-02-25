# Keyboard-Only Workflow Guide

This guide explains how to use your NixOS system with minimal mouse interaction.

## 🚀 Quick Start

### Essential Keyboard Shortcuts

#### Application Launchers
- `Alt + n`: Rofi application launcher
- `Alt + w`: Rofi window switcher
- `Alt + e`: Rofi emoji picker
- `Alt + f`: Rofi file browser
- `Alt + s`: Rofi system actions
- `Super + Return`: Terminal (Kitty)
- `Super + b`: Qutebrowser (keyboard-driven browser)
- `Super + e`: File manager (Yazi)
- `Super + t`: System monitor (btop)

#### Window Management
- `Super + q`: Close window
- `Super + h`: Minimize window
- `Super + f`: Toggle maximized
- `Super + F11`: Toggle fullscreen
- `Alt + Tab`: Switch between applications
- `Super + Tab`: Switch between windows

#### Workspace Management
- `Super + 1-0`: Switch to workspace 1-10
- `Super + ← →`: Switch between workspaces
- `Shift + Super + 1-0`: Move window to workspace 1-10
- `Shift + Super + ← →`: Move window to adjacent workspace

## 📱 Applications

### Web Browsing
1. **Qutebrowser** (Primary - fully keyboard-driven)
   - `o`: Open URL
   - `f`: Follow links
   - `d`: Close tab
   - `u`: Undo close tab
   - `J/K`: Switch tabs
   - `r`: Reload
   - `b`: Show bookmarks
   - `H/L`: Back/forward
   - `/`: Search in page

2. **Other Browsers with Vimium**
   - Install Vimium extension in Chrome/Brave/Firefox
   - `f`: Follow links
   - `j/k`: Scroll down/up
   - `gg/G`: Top/bottom of page
   - `t`: New tab
   - `x`: Close tab
   - `X`: Restore closed tab

### File Management
1. **Yazi** (Primary - keyboard-driven)
   - `j/k`: Navigate up/down
   - `h/l`: Back/forward directories
   - `Enter`: Open file/directory
   - `Space`: Select file
   - `y`: Copy
   - `d`: Cut
   - `p`: Paste
   - `r`: Rename
   - `Delete`: Delete
   - `Ctrl + h`: Toggle hidden files
   - `q`: Quit

2. **Ranger** (Alternative)
   - Similar keybindings to Yazi
   - `zh`: Toggle hidden files
   - `S`: Open shell in current directory

### Terminal Workflow
1. **Kitty Terminal**
   - `Ctrl + Shift + Enter`: New window
   - `Ctrl + Shift + t`: New tab
   - `Ctrl + Shift + ]`: Next window
   - `Ctrl + Shift + [`: Previous window
   - `Ctrl + Shift + l`: Next layout
   - `Ctrl + Shift + z`: Toggle stack layout

2. **Tmux** (Enhanced configuration)
   - `Ctrl + a`: Prefix key
   - `Ctrl + a |`: Split horizontally
   - `Ctrl + a -`: Split vertically
   - `Ctrl + a h/j/k/l`: Navigate panes
   - `Ctrl + a H/J/K/L`: Resize panes
   - `Ctrl + a c`: New window
   - `Ctrl + a g`: Git status window
   - `Ctrl + a t`: System monitor window
   - `Ctrl + a y`: File manager window

### Text Editing
- **Neovim** (Default editor)
  - Already configured as default
  - Access with `v` or `nvim` commands
  - Edit configs: `edit-config` or `edit-home` aliases

## 🔧 System Management

### Quick Commands (Aliases)
- `rebuild`: Rebuild NixOS system
- `rebuild-test`: Test configuration
- `update-flake`: Update flake inputs
- `monitor`: System monitor (btop)
- `web`: Launch qutebrowser
- `fm`: File manager (yazi)
- `r`: Ranger file manager

### System Actions via Rofi (`Alt + s`)
- Lock screen, sleep, restart, shutdown
- Open system settings
- System monitor, disk usage
- Network, audio, display settings
- Rebuild NixOS system
- Update system

## 🎯 Productivity Tips

### Shell Enhancements
- **Zoxide**: `cd` is aliased to `z` for smart directory jumping
- **Atuin**: Enhanced shell history with `Ctrl + r`
- **Eza**: Enhanced `ls` with colors and icons
- **Bat**: Enhanced `cat` with syntax highlighting
- **Ripgrep**: `grep` alias for faster searching
- **Fd**: `find` alias for faster file finding

### Git Workflow
- `g`: Git command
- `ga`: Git add
- `gc`: Git commit
- `gst`: Git status
- `gp`: Git push
- `gl`: Git pull
- `glog`: Git log with graph

### Development Workflow
- `d`: Docker command
- `dc`: Docker compose
- `dps`: Docker ps
- `di`: Docker images

## 🎨 Customization

### Tmux Sessions
Create dedicated sessions for different projects:
```bash
tmux new-session -d -s work
tmux new-session -d -s personal
tmux new-session -d -s dev
```

### Rofi Themes
- Current theme: DarkBlue
- Modify in `~/.dotfiles/system/home.nix`
- Available themes: `rofi-theme-selector`

### Keybinding Customization
- GNOME shortcuts: `~/.dotfiles/system/home.nix` (dconf settings)
- Kitty shortcuts: `~/.dotfiles/system/home.nix` (kitty.keybindings)
- Tmux shortcuts: `~/.dotfiles/users/felipe/home-modules/shell.nix` (programs.tmux.extraConfig)

## 🔍 Troubleshooting

### Common Issues
1. **Rofi not showing custom modes**
   - Ensure scripts are executable: `chmod +x ~/.dotfiles/system/applications/rofi/*.sh`
   - Check script paths in configuration

2. **Keyboard shortcuts not working**
   - Rebuild system: `rebuild`
   - Check for conflicts in GNOME settings

3. **Tmux prefix not working**
   - Prefix changed from `Ctrl + b` to `Ctrl + a`
   - Reload tmux config: `Ctrl + a r`

### Performance Tips
- Use `btop` instead of `htop` for better performance
- Use `dust` instead of `du` for faster disk usage
- Use `duf` instead of `df` for better disk info
- Use `fd` instead of `find` for faster file searching

## 🚀 Advanced Usage

### Multiple Workspace Setup
1. Use workspaces 1-4 for different contexts:
   - Workspace 1: Development
   - Workspace 2: Communication
   - Workspace 3: Web browsing
   - Workspace 4: System monitoring

2. Move frequently used applications to specific workspaces:
   ```bash
   # Move current window to workspace 2
   Super + Shift + 2
   ```

### Terminal Multiplexing
1. Use tmux for persistent sessions:
   ```bash
   tmux new -s coding
   tmux attach -t coding
   ```

2. Use Kitty layouts for temporary splits:
   ```bash
   Ctrl + Shift + l  # Cycle through layouts
   Ctrl + Shift + z  # Toggle stack layout
   ```

This setup provides a complete keyboard-driven workflow while maintaining the familiarity of GNOME for GUI applications when needed.
