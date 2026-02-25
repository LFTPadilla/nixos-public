#!/usr/bin/env bash

# Eco-Mode Script
# Switches system to power-saving mode for reduced energy consumption

set -euo pipefail

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ECO-MODE: $1" | tee -a /tmp/power-management.log
}

# Detect primary Wi‑Fi interface (wlp*/wlan*)
detect_wifi_iface() {
    local iface=""
    if command -v iw >/dev/null 2>&1; then
        iface=$(iw dev | awk '$1=="Interface" {print $2; exit}')
    fi
    if [[ -z "${iface}" ]] && command -v nmcli >/dev/null 2>&1; then
        iface=$(nmcli -t -f DEVICE,TYPE device | awk -F: '$2=="wifi"{print $1; exit}')
    fi
    echo "${iface}"
}

set_wifi_powersave_on() {
    local iface="$1"
    if [[ -z "${iface}" ]]; then
        log "No Wi‑Fi interface found; skipping Wi‑Fi power save"
        return 0
    fi
    if command -v iw >/dev/null 2>&1; then
        if ! iw dev "${iface}" set power_save on 2>/dev/null; then
            log "Failed to enable Wi‑Fi power save via iw on ${iface}"
        else
            log "Enabled Wi‑Fi power save on ${iface}"
        fi
    else
        if ! iwconfig "${iface}" power on >/dev/null 2>&1; then
            log "Failed to enable Wi‑Fi power save via iwconfig on ${iface}"
        else
            log "Enabled Wi‑Fi power save (iwconfig) on ${iface}"
        fi
    fi
}

# Check if running as root (needed for CPU governor changes)
if [[ $EUID -ne 0 ]]; then
    log "ERROR: This script must be run as root (use sudo)"
    exit 1
fi

log "Activating eco-mode..."

# 1. Set CPU governor to powersave
log "Setting CPU governor to powersave"
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    if [[ -f "$cpu" ]]; then
        echo "powersave" > "$cpu"
    fi
done

# 2. Reduce display brightness (if available)
if command -v brightnessctl >/dev/null 2>&1; then
    log "Reducing display brightness to 30%"
    brightnessctl set 30% >/dev/null 2>&1 || true
fi

# 3. Set power profile to power-saver (if available)
if command -v powerprofilesctl >/dev/null 2>&1; then
    log "Setting power profile to power-saver"
    powerprofilesctl set power-saver >/dev/null 2>&1 || true
fi

# 4. Reduce Wi‑Fi power consumption
log "Enabling Wi‑Fi power save"
set_wifi_powersave_on "$(detect_wifi_iface)"

# 5. Sync filesystems to reduce disk activity
log "Syncing filesystems"
sync

# 6. Set kernel parameters for power saving
log "Setting kernel parameters for power saving"
echo 1 > /proc/sys/vm/laptop_mode 2>/dev/null || true
echo 1500 > /proc/sys/vm/dirty_writeback_centisecs 2>/dev/null || true

# 7. Reduce USB power consumption (but never touch network adapters)
log "Enabling USB autosuspend (excluding NICs)"

# Build list of USB device bases that provide network interfaces
mapfile -t USB_NET_BASES < <(for p in /sys/bus/usb/devices/*:*; do
    [[ -d "$p/net" ]] && echo "${p%:*}"
done | sort -u)

is_usb_net_base() {
    local dir="$1"
    for b in "${USB_NET_BASES[@]}"; do
        [[ "$dir" == "$b" ]] && return 0
    done
    return 1
}

# Set autosuspend delay
for path in /sys/bus/usb/devices/*/power/autosuspend_delay_ms; do
    [[ -f "$path" ]] || continue
    devdir="${path%/power/autosuspend_delay_ms}"
    base="${devdir%%:*}"
    if is_usb_net_base "$devdir" || is_usb_net_base "$base"; then
        log "Skip USB NIC autosuspend_delay: $devdir"
        continue
    fi
    echo 1000 > "$path" 2>/dev/null || true
done

# Enable autosuspend for non-network USB devices
for path in /sys/bus/usb/devices/*/power/control; do
    [[ -f "$path" ]] || continue
    devdir="${path%/power/control}"
    base="${devdir%%:*}"
    if is_usb_net_base "$devdir" || is_usb_net_base "$base"; then
        log "Skip USB NIC power control: $devdir"
        continue
    fi
    echo auto > "$path" 2>/dev/null || true
done

# 8. Signal completion
log "Eco-mode activated successfully"
echo "eco" > /tmp/power-mode-status

exit 0
