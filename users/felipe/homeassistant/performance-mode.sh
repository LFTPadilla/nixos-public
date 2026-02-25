#!/usr/bin/env bash

# Performance-Mode Script
# Switches system to high-performance mode for maximum responsiveness

set -euo pipefail

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] PERFORMANCE-MODE: $1" | tee -a /tmp/power-management.log
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

set_wifi_powersave_off() {
    local iface="$1"
    if [[ -z "${iface}" ]]; then
        log "No Wi‑Fi interface found; skipping Wi‑Fi power save disable"
        return 0
    fi
    if command -v iw >/dev/null 2>&1; then
        if ! iw dev "${iface}" set power_save off 2>/dev/null; then
            log "Failed to disable Wi‑Fi power save via iw on ${iface}"
        else
            log "Disabled Wi‑Fi power save on ${iface}"
        fi
    else
        if ! iwconfig "${iface}" power off >/dev/null 2>&1; then
            log "Failed to disable Wi‑Fi power save via iwconfig on ${iface}"
        else
            log "Disabled Wi‑Fi power save (iwconfig) on ${iface}"
        fi
    fi
}

# Check if running as root (needed for CPU governor changes)
if [[ $EUID -ne 0 ]]; then
    log "ERROR: This script must be run as root (use sudo)"
    exit 1
fi

log "Activating performance-mode..."

# 1. Set CPU governor to performance
log "Setting CPU governor to performance"
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    if [[ -f "$cpu" ]]; then
        echo "performance" > "$cpu"
    fi
done

# 2. Restore display brightness (if available)
if command -v brightnessctl >/dev/null 2>&1; then
    log "Restoring display brightness to 80%"
    brightnessctl set 80% >/dev/null 2>&1 || true
fi

# 3. Set power profile to performance (if available)
if command -v powerprofilesctl >/dev/null 2>&1; then
    log "Setting power profile to performance"
    powerprofilesctl set performance >/dev/null 2>&1 || true
fi

# 4. Disable Wi‑Fi power save for better performance
log "Disabling Wi‑Fi power save"
set_wifi_powersave_off "$(detect_wifi_iface)"

# 5. Optimize kernel parameters for performance
log "Setting kernel parameters for performance"
echo 0 > /proc/sys/vm/laptop_mode 2>/dev/null || true
echo 500 > /proc/sys/vm/dirty_writeback_centisecs 2>/dev/null || true

# 6. Disable USB autosuspend for better responsiveness (excluding NICs)
log "Disabling USB autosuspend (excluding NICs)"

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

for path in /sys/bus/usb/devices/*/power/control; do
    [[ -f "$path" ]] || continue
    devdir="${path%/power/control}"
    base="${devdir%%:*}"
    if is_usb_net_base "$devdir" || is_usb_net_base "$base"; then
        log "Skip USB NIC power control: $devdir"
        continue
    fi
    echo on > "$path" 2>/dev/null || true
done

# 7. Boost I/O scheduler performance
log "Optimizing I/O scheduler"
for disk in /sys/block/*/queue/scheduler; do
    if [[ -f "$disk" ]]; then
        echo mq-deadline > "$disk" 2>/dev/null || true
    fi
done

# 8. Signal completion
log "Performance-mode activated successfully"
echo "performance" > /tmp/power-mode-status

exit 0
