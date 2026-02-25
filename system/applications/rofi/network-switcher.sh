#!/usr/bin/env bash

# Rofi network switcher script
# Usage: rofi -show network -modi "network:~/.dotfiles/system/applications/rofi/network-switcher.sh"

set -euo pipefail

# Find rofi-wrapper script
ROFI_WRAPPER="$HOME/.dotfiles/system/applications/rofi/rofi-wrapper.sh"
if [ -x "$ROFI_WRAPPER" ]; then
    ROFI_CMD="$ROFI_WRAPPER"
else
    ROFI_CMD="rofi"
fi

# Notification helper
notify_user() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"

    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u "$urgency" "$title" "$message"
    fi
}

# Get password via rofi
get_password() {
    local ssid="$1"
    "$ROFI_CMD" -dmenu -password \
        -p "Password for $ssid:" \
        -theme-str 'inputbar { enabled: true; }' \
        -theme-str 'listview { enabled: false; }'
}

# Connect to network
connect_network() {
    local selection="$1"

    # Strip icons and extract SSID
    local ssid=$(echo "$selection" | sed -E 's/^[^[:alnum:]]+ //; s/ \([^)]+\)$//')

    # Check if already connected
    if echo "$selection" | grep -q "⚡"; then
        notify_user "Network" "Already connected to $ssid"
        return
    fi

    # Check if it's a saved network
    if nmcli connection show | grep -q "$ssid"; then
        # Saved network, just activate
        if nmcli connection up "$ssid" 2>/dev/null; then
            notify_user "Network" "Connected to $ssid" "normal"
        else
            notify_user "Network" "Failed to connect to $ssid" "critical"
        fi
    else
        # New network, need password
        if echo "$selection" | grep -q "🔒"; then
            # Secured network
            password=$(get_password "$ssid")
            if [ -z "$password" ]; then
                notify_user "Network" "Connection cancelled" "low"
                return
            fi

            if nmcli device wifi connect "$ssid" password "$password" 2>/dev/null; then
                notify_user "Network" "Connected to $ssid" "normal"
            else
                notify_user "Network" "Failed to connect to $ssid\nCheck password and try again" "critical"
            fi
        else
            # Open network
            if nmcli device wifi connect "$ssid" 2>/dev/null; then
                notify_user "Network" "Connected to $ssid" "normal"
            else
                notify_user "Network" "Failed to connect to $ssid" "critical"
            fi
        fi
    fi
}

# Handle special actions
handle_action() {
    local action="$1"

    case "$action" in
        "🔄 Rescan Networks")
            nmcli device wifi rescan 2>/dev/null
            notify_user "Network" "Rescanning networks..."
            # Restart the script to show updated list
            exec "$0"
            ;;
        "📡 Enable WiFi")
            nmcli radio wifi on
            notify_user "Network" "WiFi enabled"
            exec "$0"
            ;;
        "📴 Disable WiFi")
            nmcli radio wifi off
            notify_user "Network" "WiFi disabled"
            exit 0
            ;;
        "⚙️  Network Settings")
            if command -v gnome-control-center >/dev/null 2>&1; then
                setsid -f gnome-control-center network >/dev/null 2>&1
            elif command -v nmtui >/dev/null 2>&1; then
                setsid -f kitty -e nmtui >/dev/null 2>&1
            fi
            exit 0
            ;;
    esac
}

# Check if we received a selection
if [ -n "${1:-}" ]; then
    # Check if it's an action
    if echo "$1" | grep -qE "^(🔄|📡|📴|⚙️)"; then
        handle_action "$1"
    else
        connect_network "$1"
    fi
    exit 0
fi

# Show prompt
echo -e "\0prompt\x1f📶 WiFi Networks"

# Check if WiFi is enabled
if ! nmcli radio wifi 2>/dev/null | grep -q "enabled"; then
    echo "📴 WiFi is disabled"
    echo "📡 Enable WiFi"
    echo "⚙️  Network Settings"
    exit 0
fi

# Get current connection
current_ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes:' | cut -d: -f2)

# Show action items
echo "🔄 Rescan Networks"
echo "📴 Disable WiFi"
echo "⚙️  Network Settings"
echo "---"

# List available networks
nmcli -f SSID,SIGNAL,SECURITY device wifi list 2>/dev/null | tail -n +2 | while read -r ssid signal security; do
    # Skip empty SSIDs
    [ -z "$ssid" ] && continue

    # Determine icon based on signal strength and security
    if [ "$ssid" = "$current_ssid" ]; then
        icon="⚡"
    elif [ "$signal" -ge 75 ]; then
        icon="📶"
    elif [ "$signal" -ge 50 ]; then
        icon="📡"
    elif [ "$signal" -ge 25 ]; then
        icon="📊"
    else
        icon="📉"
    fi

    # Add lock icon for secured networks
    if echo "$security" | grep -qv "^--$\|^$"; then
        security_icon="🔒"
    else
        security_icon="🔓"
    fi

    # Format: Icon SSID (signal%)
    echo "$icon $security_icon $ssid ($signal%)"
done
