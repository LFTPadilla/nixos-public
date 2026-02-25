# MacBook Pro - nix-darwin Configuration

Satellite workstation setup optimized for remote work with the main NixOS rig.

## First-Time Setup

### 1. Create SSH Key and Add to GitHub
```bash
ssh-keygen -t ed25519 -C "your@email.com"
ssh-add ~/.ssh/id_ed25519
pbcopy < ~/.ssh/id_ed25519.pub
# Add to github.com → Settings → SSH Keys
```

### 2. Clone Dotfiles
```bash
git clone git@github.com:your-username/dotfiles.git ~/.dotfiles
```

### 3. Install Nix Package Manager
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### 4. Open a New Terminal
After installing Nix, **open a new terminal window** to ensure the Nix environment is loaded.

### 5. First-Time nix-darwin Build
```bash
sudo nix run nix-darwin \
  --extra-experimental-features "nix-command flakes" \
  -- switch --flake ~/.dotfiles#mac
```

## Quick Commands

```bash
# Rebuild and apply configuration
darwin-rebuild switch --flake ~/.dotfiles#mac

# Test configuration without applying
darwin-rebuild check --flake ~/.dotfiles#mac

# Update flake inputs
nix flake update --flake ~/.dotfiles

# Update specific input (e.g., nix-darwin)
nix flake lock --update-input nix-darwin
```

## What's Installed

### Nix System Packages (CLI)
- **Core**: coreutils, gnused, gawk, findutils
- **Dev**: git, gh, neovim, tmux, lazygit, mosh
- **Shell**: zsh, starship, zoxide, fzf, ripgrep, fd, eza, bat, jq, yq
- **Files**: yazi
- **Monitoring**: htop, bottom
- **Nix tools**: nil (LSP), nixfmt-rfc-style, alejandra

### Home Manager Packages
- **Dev**: nodejs, python3, zed-editor
- **Tools**: btop, mosh, carapace

### Homebrew Casks (GUI)
- **Remote**: moonlight
- **Terminal**: kitty, ghostty
- **Dev**: visual-studio-code, zed, orbstack
- **Browser**: brave-browser, zen
- **Utilities**: raycast, stats, aldente, karabiner-elements, hiddenbar
- **Media**: iina
- **Productivity**: obsidian
- **File sharing**: localsend, nextcloud

### Homebrew Brews (CLI)
- ncdu, pam-reattach, nmap, go, node

### Window Manager (Homebrew)
- **yabai**: Tiling window manager (BSP layout) - `brew install koekeishiya/formulae/yabai`
- **skhd**: Hotkey daemon for keybindings - `brew install koekeishiya/formulae/skhd`

> **Note**: yabai and skhd are installed via Homebrew instead of nix-darwin to avoid macOS accessibility permission issues. Nix store paths change on rebuilds, causing repeated permission prompts. Homebrew binaries have stable paths and are properly codesigned.

## System Settings Applied

- Caps Lock remapped to Control
- Fast key repeat (2/15)
- Tap to click enabled
- Three finger drag enabled
- Dock autohide with no delay
- Finder shows all files and extensions
- Screenshots saved to ~/Pictures/Screenshots (PNG, no shadow)
- Touch ID for sudo
- Natural scrolling enabled
- 24-hour clock

## Keybindings (yabai + skhd)

### Window Focus
| Key | Action |
|-----|--------|
| `Alt + h/j/k/l` | Focus window left/down/up/right |
| `Alt + n/p` | Focus next/previous window |

### Window Movement
| Key | Action |
|-----|--------|
| `Shift + Alt + h/j/k/l` | Swap window left/down/up/right |
| `Shift + Alt + 0` | Balance all windows |

### Window Resize
| Key | Action |
|-----|--------|
| `Ctrl + Alt + h/j/k/l` | Resize window |

### Layout
| Key | Action |
|-----|--------|
| `Alt + r` | Rotate layout 270° |
| `Alt + y` | Mirror y-axis |
| `Alt + x` | Mirror x-axis |
| `Alt + t` | Toggle float |
| `Alt + f` | Toggle fullscreen |
| `Alt + s` | Toggle split |
| `Shift + Alt + Space` | Toggle bsp/stack layout |

### Workspaces
| Key | Action |
|-----|--------|
| `Alt + 1-6` | Focus workspace 1-6 |
| `Shift + Alt + 1-6` | Move window to workspace and follow |
| `Ctrl + Shift + 1-6` | Move window to workspace (don't follow) |

### Applications
| Key | Action |
|-----|--------|
| `Alt + Return` | Open Kitty |
| `Alt + d` | Open Raycast |
| `Alt + b` | Open Brave Browser |
| `Alt + e` | Open Finder |
| `Alt + m` | Open Moonlight |
| `Alt + q` | Close window |
| `Alt + w` | Minimize window |

### Service Restart
| Key | Action |
|-----|--------|
| `Ctrl + Alt + r` | Restart yabai + skhd |

## Shell Aliases

```bash
# Rebuild
rebuild          # darwin-rebuild switch
rebuild-test     # darwin-rebuild check

# Remote workstation
ws               # SSH to workstation
wst              # SSH + tmux attach
stream           # Open Moonlight

# Navigation
dot              # cd ~/.dotfiles
dev              # cd ~/Developer
dl               # cd ~/Downloads

# Tools
v, vim           # neovim
y                # yazi
lg               # lazygit
```

## Manual Setup Required

### 1. Accessibility Permissions (yabai/skhd)
When you first start yabai/skhd, macOS will prompt for accessibility permissions.

**Option 1: Grant via prompt** (easiest)
- When the prompt appears, click "Open System Settings"
- Grant permission to your terminal app (Kitty)

**Option 2: Manual grant**
- System Settings → Privacy & Security → Accessibility
- Click `+` and add your terminal app (Kitty, Terminal, etc.)

> **Important**: Grant permissions to your **terminal app**, not the binaries. yabai/skhd inherit permissions from the terminal that launches them.

### 2. Full Disk Access (Terminal)
For homebrew cleanup to work:
- System Settings → Privacy & Security → Full Disk Access
- Add your terminal (Kitty/Terminal.app)

### 3. Karabiner-Elements Input Monitoring
Karabiner needs Input Monitoring permissions to detect keyboard input.

**Grant Input Monitoring permissions:**
1. System Settings → Privacy & Security → Input Monitoring
2. Enable these Karabiner components:
   - `karabiner_grabber`
   - `karabiner_observer`
   - `Karabiner-Elements`
   - `Karabiner-EventViewer`

**If not in the list, manually add core services:**
- Click `+` and navigate to `/Library/Application Support/org.pqrs/Karabiner-Elements/bin/`
- Add both:
  - `karabiner_grabber` (core service)
  - `karabiner_observer` (core service)

**Restart Karabiner after granting permissions:**
```bash
killall karabiner_grabber karabiner_observer
launchctl kickstart -k gui/$(id -u)/org.pqrs.karabiner.karabiner_grabber
launchctl kickstart -k gui/$(id -u)/org.pqrs.karabiner.karabiner_observer
```

**Configuration:**
- Config file: `~/.config/karabiner/karabiner.json`
- Complex modification: Option+1-9 → Control+1-9 (desktop switching like Hyprland)

### 4. Install Window Manager (yabai + skhd)
```bash
# Install both via Homebrew
brew install koekeishiya/formulae/yabai
brew install koekeishiya/formulae/skhd

# Copy configs from dotfiles (if not already present)
# They are created at ~/.yabairc and ~/.skhdrc

# Start services (auto-start on login)
yabai --start-service
skhd --start-service
```

### 5. yabai Scripting Addition (Optional)
For full yabai features (moving windows between displays):
1. Boot into Recovery Mode (hold power button)
2. Open Terminal from Utilities menu
3. Run: `csrutil enable --without fs --without debug --without nvram`
4. Reboot
5. Run: `sudo yabai --load-sa`

## Window Manager Configuration

Since yabai and skhd are managed via Homebrew (not nix-darwin), their configs are in home directory files:

### Config Files
- `~/.yabairc` - yabai window manager configuration
- `~/.skhdrc` - skhd keyboard shortcuts configuration

### Updating Configs
```bash
# Edit configs directly
nvim ~/.yabairc
nvim ~/.skhdrc

# Restart services to apply changes
yabai --restart-service
skhd --restart-service
```

### Service Management
```bash
# Start services (auto-start on login)
yabai --start-service
skhd --start-service

# Stop services
yabai --stop-service
skhd --stop-service

# Restart services
yabai --restart-service
skhd --restart-service

# Check status
brew services list | grep -E 'yabai|skhd'
```

> **Note**: The yabai/skhd configs in `hosts/mac/wm.nix` are kept for reference only and are NOT applied. Edit the home directory files instead.

## Troubleshooting

### "experimental Nix feature 'nix-command' is disabled"
```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### "zsh: no matches found: ...#mac"
Quote the flake path:
```bash
darwin-rebuild switch --flake '~/.dotfiles#mac'
```

### Gatekeeper blocks app
```bash
xattr -d com.apple.quarantine /Applications/AppName.app
```
Or: System Settings → Privacy & Security → Open Anyway

### yabai/skhd not working
1. **Check Accessibility permissions**
   - System Settings → Privacy & Security → Accessibility
   - Ensure your terminal app (Kitty) is enabled

2. **Restart services**
   ```bash
   yabai --restart-service
   skhd --restart-service
   ```
   Or use keyboard shortcut: `Ctrl + Alt + r`

3. **Check service status**
   ```bash
   brew services list | grep -E 'yabai|skhd'
   ```

4. **View logs**
   ```bash
   tail -f /tmp/yabai_$USER.out.log
   tail -f /tmp/skhd_$USER.out.log
   ```

5. **Reinstall if broken**
   ```bash
   brew reinstall koekeishiya/formulae/yabai
   brew reinstall koekeishiya/formulae/skhd
   ```

### Shell not loading correctly
```bash
exec zsh
```

## File Structure

```
hosts/mac/
├── default.nix      # Main system configuration
├── homebrew.nix     # Homebrew casks and brews
├── wm.nix           # yabai + skhd window manager
└── README.md        # This file

system/
├── home-darwin.nix  # Home Manager config for macOS
└── nvim/            # Shared neovim configuration
```

## Related Configs

- **NixOS main**: `hosts/main/configuration.nix`
- **Shell config**: `users/felipe/home-modules/shell.nix`
- **Flake**: `flake.nix`
