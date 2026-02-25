#!/usr/bin/env bash

# Rofi system actions script
# Usage: rofi -show system-actions -modi "system-actions:~/.dotfiles/system/applications/rofi/system-actions.sh"

# Define available actions
actions=(
    "🔒 Lock Screen"
    "🌙 Sleep"
    "🔄 Restart"
    "⏻  Shutdown"
    "🚪 Logout"
    "🖥️  Display Settings"
    "🔊 Audio Settings"
    "🌐 Network Settings"
    "🔋 Power Settings"
    "⚙️  System Settings"
    "🖱️  Mouse & Touchpad"
    "⌨️  Keyboard Settings"
    "📱 Bluetooth"
    "🔧 System Monitor"
    "📊 Disk Usage"
    "🌡️  Temperature Monitor"
    "🔄 Rebuild NixOS"
    "📦 Update System"
    "🗂️  File Manager"
    "🌐 Web Browser"
    "📷 Camera Preview"
    "📝 Text Editor"
    "💻 Terminal"
    "📸 Screenshot"
    "🚀 Work Setup (Hypr)"
)

notify_missing() {
    local msg="$1"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "System action" "$msg"
    else
        printf '%s\n' "$msg" >&2
    fi
}

notify_info() {
    local msg="$1"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "System action" "$msg"
    fi
}

run_first_available() {
    local description="$1"
    shift
    for cmd in "$@"; do
        local binary=${cmd%% *}
        if command -v "$binary" >/dev/null 2>&1; then
            nohup bash -lc "$cmd" >/dev/null 2>&1 &
            return 0
        fi
    done
    notify_missing "$description"
}

choose_power_profile() {
    if ! command -v powerprofilesctl >/dev/null 2>&1; then
        notify_missing "powerprofilesctl not installed"
        return
    fi
    local rofi_wrapper="$HOME/.dotfiles/system/applications/rofi/rofi-wrapper.sh"
    local raw profiles current entries selection

    # Be tolerant of different powerprofilesctl output formats
    raw="$(powerprofilesctl list 2>/dev/null || true)"
    profiles="$(printf '%s\n' "$raw" | awk -F: '/:$/ { gsub(/^[[:space:]]*\*?[[:space:]]*/, "", $1); print $1 }')"

    if [[ -z "$profiles" ]]; then
        notify_missing "No power profiles available"
        return
    fi
    current=$(powerprofilesctl get 2>/dev/null | tr -d '[:space:]')
    entries=$(printf '%s\n' "$profiles" | awk -v curr="$current" '{if ($0==curr) printf "%s (active)\n", $0; else print $0}')
    if [ -x "$rofi_wrapper" ]; then
        selection=$(printf '%s\n' "$entries" | "$rofi_wrapper" -dmenu -p "Power Profile")
    elif command -v rofi >/dev/null 2>&1; then
        selection=$(printf '%s\n' "$entries" | rofi -dmenu -p "Power Profile")
    elif command -v fzf >/dev/null 2>&1; then
        selection=$(printf '%s\n' "$entries" | fzf --prompt="Power Profile> ")
    else
        kitty -e bash -lc 'powerprofilesctl list; echo; read -n 1 -s -r -p "Press any key to close..."' &
        return
    fi
    selection=${selection%% *}
    [[ -z "$selection" ]] && return
    if powerprofilesctl set "$selection"; then
        notify_info "Switched to $selection"
    fi
}

screenshot_action() {
    # Prefer Omarchy-style Wayland screenshots with annotation on Hyprland
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        if command -v grim >/dev/null 2>&1 && command -v slurp >/dev/null 2>&1 && command -v satty >/dev/null 2>&1; then
            nohup bash -lc '
                [[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
                OUTPUT_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}"
                mkdir -p "$OUTPUT_DIR"
                SELECTION="$(slurp 2>/dev/null)" || exit 0
                [ -z "$SELECTION" ] && exit 0
                grim -g "$SELECTION" - | satty --filename - \
                    --output-filename "$OUTPUT_DIR/screenshot-$(date +%Y-%m-%d_%H-%M-%S).png" \
                    --early-exit \
                    --actions-on-enter save-to-clipboard \
                    --save-after-copy \
                    --copy-command "wl-copy"
            ' >/dev/null 2>&1 &
            return 0
        elif command -v grim >/dev/null 2>&1 && command -v slurp >/dev/null 2>&1; then
            nohup bash -lc 'f="$HOME/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"; grim -g "$(slurp)" - | tee "$f" | wl-copy --type image/png' >/dev/null 2>&1 &
            return 0
        fi
    fi

    # Fallback to Flameshot (e.g. on GNOME or X11)
    if command -v flameshot >/dev/null 2>&1; then
        nohup bash -lc "flameshot gui" >/dev/null 2>&1 &
        return 0
    fi

    notify_missing "No screenshot tool available"
}
# Function to execute the selected action
execute_action() {
    case "$1" in
        "🔒 Lock Screen")
            if [[ -n "${XDG_SESSION_ID:-}" ]]; then
                loginctl lock-session "$XDG_SESSION_ID"
            else
                loginctl lock-session
            fi
            ;;
        "🌙 Sleep")
            systemctl suspend
            ;;
        "🔄 Restart")
            systemctl reboot
            ;;
        "⏻  Shutdown")
            systemctl poweroff
            ;;
        "🚪 Logout")
            hyprctl dispatch exit 0
            ;;
        "🖥️  Display Settings")
            run_first_available "No display configuration tool available" \
                "wdisplays" \
                "gnome-control-center display"
            ;;
        "🔊 Audio Settings")
            run_first_available "No audio settings utility available" \
                "pavucontrol" \
                "gnome-control-center sound"
            ;;
        "🌐 Network Settings")
            run_first_available "No network manager available" \
                "kitty -e nmtui" \
                "gnome-control-center network"
            ;;
        "🔋 Power Settings")
            choose_power_profile
            ;;
        "⚙️  System Settings")
            gnome-control-center
            ;;
        "🖱️  Mouse & Touchpad")
            run_first_available "No mouse/touchpad settings utility available" \
                "gnome-control-center mouse"
            ;;
        "⌨️  Keyboard Settings")
            run_first_available "No keyboard settings utility available" \
                "gnome-control-center keyboard"
            ;;
        "📱 Bluetooth")
            run_first_available "No Bluetooth settings utility available" \
                "gnome-control-center bluetooth"
            ;;
        "🔧 System Monitor")
            run_first_available "No system monitor available" \
                "kitty -e btop" \
                "btop"
            ;;
        "📊 Disk Usage")
            run_first_available "No disk usage utility available" \
                "kitty -e dust" \
                "dust"
            ;;
        "🌡️  Temperature Monitor")
            run_first_available "No temperature monitor available" \
                "kitty -e \"watch -n 1 sensors\"" \
                "watch -n 1 sensors"
            ;;
        "🔄 Rebuild NixOS")
            run_first_available "Could not open terminal for rebuild" \
                "kitty -e \"sudo nixos-rebuild switch --flake ~/.dotfiles#default\"" \
                "sudo nixos-rebuild switch --flake ~/.dotfiles#default"
            ;;
        "📦 Update System")
            run_first_available "Could not open terminal for system update" \
                "kitty -e \"cd ~/.dotfiles && nix flake update && sudo nixos-rebuild switch --flake .#default\"" \
                "cd ~/.dotfiles && nix flake update && sudo nixos-rebuild switch --flake .#default"
            ;;
        "🗂️  File Manager")
            run_first_available "No file manager available" \
                "dolphin" \
                "nautilus" \
                "pcmanfm-qt" \
                "thunar"
            ;;
        "🌐 Web Browser")
            run_first_available "No web browser available" \
                "qutebrowser" \
                "firefox" \
                "chromium" \
                "xdg-open https://duckduckgo.com"
            ;;
        "📝 Text Editor")
            run_first_available "No text editor available" \
                "kitty -e nvim" \
                "code" \
                "gedit"
            ;;
        "💻 Terminal")
            run_first_available "No terminal available" \
                "kitty" \
                "foot" \
                "alacritty"
            ;;
        "📷 Camera Preview")
            nohup bash -lc "$HOME/.dotfiles/system/scripts/camera-preview.sh" >/dev/null 2>&1 &
            ;;
        "📸 Screenshot")
            screenshot_action
            ;;
        "🚀 Work Setup (Hypr)")
            run_first_available "work-hypr command not available" \
                "work-hypr"
            ;;
    esac
}

# Check if we received a selection
if [ -n "$1" ]; then
    execute_action "$1"
    exit 0
fi

# Show prompt
echo -e "\0prompt\x1f⚙️  System Actions"

# List all available actions
for action in "${actions[@]}"; do
    echo "$action"
done
