# NixOS Dotfiles - Complete System Configuration

A complete NixOS system configuration with GNOME desktop, development tools, and Home Manager integration.

## 🚀 Quick Installation (New Computer)

### Prerequisites
1. Fresh NixOS installation with internet connection
2. Git installed: `nix-shell -p git`

### Installation Steps
```bash
# 1. Clone the repository
git clone https://github.com/LFTPadilla/nixos.git ~/.dotfiles

# 2. Navigate to system directory
cd ~/.dotfiles/system

# 3. Test the configuration
sudo nixos-rebuild test --flake .#default

# 4. If successful, apply permanently
sudo nixos-rebuild switch --flake .#default

# 5. Reboot to ensure all services start correctly
reboot
```

## 📋 What You Need to Backup/Restore

### Essential Files (CRITICAL - Store in secure cloud backup)
```
~/.ssh/                     # SSH keys and known_hosts
~/.gnupg/                   # GPG keys and configuration
~/.netrc                    # Network authentication credentials
~/.profile                  # User environment variables
~/.npmrc                    # npm configuration and registry tokens

```

### Application Data (Important but can be recreated)
```
~/.config/1Password/        # 1Password vault cache
~/.config/Claude/           # Claude AI conversation history
~/.config/BraveSoftware/    # Browser bookmarks and settings
~/.config/Code/             # VS Code settings and extensions
~/.config/chromium/         # Chromium browser data
~/.config/Bitwarden/        # Password manager data
```

### Development Data (Version controlled separately)
```
~/programming/              # Your project repositories
~/Documents/                # Important documents
~/Nextcloud*/               # Cloud synced files
```

## 🔧 System Features

### Desktop Environment
- **GNOME** with X11 (Wayland disabled for compatibility)
- **Custom theme switching** (dark/light mode scripts)
- **Rofi launcher** with multiple modes (apps, windows, emoji)
- **Flameshot** for screenshots with annotation
- **Custom keybindings** for productivity

### Power Management
- **GUI Control**: Settings → Power → Power Mode
- **Keyboard Shortcuts**:
  - `Super+Alt+1` → Power Saver mode
  - `Super+Alt+2` → Balanced mode
  - `Super+Alt+3` → Performance mode
- **Terminal Commands**: `power-saver`, `balanced`, `performance`

### Development Tools
- **Languages**: Node.js 22, Python 3, Docker support
- **Editors**: Neovim (default), VS Code, Cursor
- **Shell**: Zsh + Oh-My-Zsh + Starship prompt
- **Terminal**: Kitty with Catppuccin theme
- **File Manager**: Yazi with custom configuration
- **Version Control**: Git with helpful aliases

### System Services
- **Tailscale VPN** for remote access
- **Sunshine** game streaming server
- **Home Assistant Companion** for automation
- **ActivityWatch** for time tracking
- **Auto-cpufreq** for power management

## 🏗️ Architecture Overview

### Core Files
```
system/
├── flake.nix                 # Nix flake definition and inputs
├── configuration.nix         # Main system configuration
├── home.nix                 # Home Manager user configuration
├── hardware-configuration.nix # Hardware-specific settings
└── packages/                # Package definitions
    ├── system.nix           # System-wide packages
    ├── user.nix             # User packages
    ├── development.nix      # Development tools
    └── desktop.nix          # Desktop applications
```

### Application Configs
```
system/applications/
├── rofi/                    # Rofi launcher configuration
├── sunshine.nix             # Game streaming setup
└── vm.nix                   # Virtual machine configuration
```

### Scripts & Automation
```
system/scripts/
├── translate.sh             # Quick translation tool
└── translate-selection.sh   # Translate selected text

users/felipe/homeassistant/
├── *.sh                     # Power management scripts
└── hacompanion.toml         # Home Assistant config
```

## ⚙️ Customization

### Adding New Packages
```bash
# System packages (requires rebuild)
# Edit system/packages/system.nix or user.nix

# User packages via Home Manager
# Edit system/packages/user.nix

# Then rebuild
rebuild-test    # Test first
rebuild         # Apply changes
```

### Modifying Services
```bash
# Edit hosts/main/configuration.nix
# Add/modify services section

# Test and apply
sudo nixos-rebuild test --flake ~/.dotfiles#default
sudo nixos-rebuild switch --flake ~/.dotfiles#default
```

### Updating System
```bash
# Update flake inputs
update-flake

# Rebuild with new packages
rebuild
```

## 🔄 Maintenance Commands

### Available Aliases
```bash
# System management
rebuild           # Apply configuration changes
rebuild-test      # Test configuration without switching
rebuild-boot      # Apply on next boot
update-flake      # Update all flake inputs

# Power management
power-saver       # Switch to power saving mode
balanced          # Switch to balanced mode
performance       # Switch to performance mode
power-status      # Show current power profile

# Quick editing
edit-config       # Edit main system configuration
edit-home         # Edit Home Manager configuration
dot               # Navigate to dotfiles directory

# Theme switching
dark-theme        # Switch to dark theme
light-theme       # Switch to light theme
```

### Regular Maintenance
```bash
# Weekly maintenance
nix-collect-garbage -d              # Clean old generations
sudo nixos-rebuild switch --upgrade # Update system
```

## 📚 Documentation

- [Neovim Guide](docs/nvim.md) - Shortcuts and configuration for the text editor
- [Hyprland Shortcuts](docs/hyprland-shortcuts.md) - Window manager keybindings
- [Tmux Guide](docs/tmux.md) - Terminal multiplexer commands

## 🆘 Troubleshooting

### Boot Issues
```bash
# Roll back to previous generation
sudo nixos-rebuild switch --rollback

# Check available generations
sudo nix-env -p /nix/var/nix/profiles/system --list-generations
```

### Build Errors
```bash
# Detailed error information
sudo nixos-rebuild switch --flake ~/.dotfiles#default --show-trace

# Check flake issues
nix flake check ~/.dotfiles/
```

### Service Issues
```bash
# Check service status
systemctl status <service-name>

# View logs
journalctl -xeu <service-name>

# Restart service
sudo systemctl restart <service-name>
```

## 🔐 Security Considerations

### First Boot Setup
1. **Change default passwords** for all accounts
2. **Set up SSH keys** (generate new ones if lost)
3. **Configure GPG keys** for signing commits
4. **Set up 1Password** or password manager
5. **Configure Tailscale** for secure remote access

### Network Security
- Firewall is enabled with specific port rules
- SSH has rate limiting configured
- VPN integration available (Tailscale, ProtonVPN)

## 📱 Integrations

### Home Assistant
- Companion service runs automatically
- Power management integration
- System monitoring capabilities

### Cloud Services
- Nextcloud integration for file sync
- GitHub integration for code repositories
- Various cloud storage providers supported

## 🚨 Recovery Guide

### Complete System Loss
1. **Fresh NixOS install** with same username
2. **Restore SSH keys** from backup to `~/.ssh/`
3. **Clone dotfiles**: `git clone <your-repo> ~/.dotfiles`
4. **Run installation steps** above
5. **Restore application data** from cloud backups
6. **Reconfigure services** (Tailscale, 1Password, etc.)

### Partial Recovery
- **Lost configs**: `git checkout` to restore specific files
- **Broken build**: Use `--rollback` to previous generation
- **Service issues**: Check systemd logs and restart services

## 📚 Additional Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Options](https://mipmip.github.io/home-manager-option-search/)
- [Nix Package Search](https://search.nixos.org/packages)

---

**Last Updated**: $(date)
**NixOS Version**: 25.05 (Unstable)
**Home Manager**: Latest

For questions or issues, check the git history or create an issue in the repository.
