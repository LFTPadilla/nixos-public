#!/usr/bin/env bash

# Power Management Activity Monitor
# Monitors system activity and manages power modes for Home Assistant

set -euo pipefail

# Configuration
IDLE_THRESHOLD=600000  # 10 minutes in milliseconds
POWER_MODE_FILE="/tmp/power-mode-status"
LAST_ACTIVITY_FILE="/tmp/last-activity"

# Initialize power mode status if it doesn't exist
if [[ ! -f "$POWER_MODE_FILE" ]]; then
    echo "performance" > "$POWER_MODE_FILE"
fi

# Function to get current power mode
get_power_mode() {
    if [[ -f "$POWER_MODE_FILE" ]]; then
        cat "$POWER_MODE_FILE"
    else
        echo "unknown"
    fi
}

# Function to get idle time in milliseconds
get_idle_time() {
    if command -v xprintidle >/dev/null 2>&1; then
        xprintidle 2>/dev/null || echo 0
    else
        echo 0
    fi
}

# Function to check if system is busy
is_system_busy() {
    local load_avg
    load_avg=$(uptime | awk '{print $10}' | tr -d ',')
    
    # Check if load average is above 2.0 (system is busy)
    # Use awk for floating point comparison
    if awk "BEGIN {exit !($load_avg > 2.0)}"; then
        return 0  # System is busy
    fi
    
    return 1  # System is not busy
}

# Function to check if in meeting (using existing meeting detection)
is_in_meeting() {
    local meeting_script="/home/felipe/.dotfiles/users/felipe/homeassistant/meeting-detection.sh"
    if [[ -f "$meeting_script" ]]; then
        local meeting_status
        meeting_status=$("$meeting_script" | head -n 1)
        [[ "$meeting_status" == "1" ]]
    else
        return 1  # Not in meeting
    fi
}

# Function to check CPU usage
get_cpu_usage() {
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' | sed 's/,//')
    echo "${cpu_usage:-0}"
}

# Function to switch to eco mode
switch_to_eco() {
    local eco_script="/home/felipe/.dotfiles/users/felipe/homeassistant/eco-mode.sh"
    if [[ -f "$eco_script" ]]; then
        sudo "$eco_script" >/dev/null 2>&1
        return $?
    fi
    return 1
}

# Function to switch to performance mode
switch_to_performance() {
    local perf_script="/home/felipe/.dotfiles/users/felipe/homeassistant/performance-mode.sh"
    if [[ -f "$perf_script" ]]; then
        sudo "$perf_script" >/dev/null 2>&1
        return $?
    fi
    return 1
}

# Get current status
current_mode=$(get_power_mode)
idle_time=$(get_idle_time)
cpu_usage=$(get_cpu_usage)
idle_minutes=$((idle_time / 60000))

# Activity detection
is_idle=$((idle_time > IDLE_THRESHOLD))
system_busy=$(is_system_busy && echo 1 || echo 0)
in_meeting=$(is_in_meeting && echo 1 || echo 0)

# Decision logic
should_be_eco=0
should_be_performance=0

if [[ $is_idle -eq 1 && $system_busy -eq 0 && $in_meeting -eq 0 ]]; then
    should_be_eco=1
elif [[ $is_idle -eq 0 || $system_busy -eq 1 || $in_meeting -eq 1 ]]; then
    should_be_performance=1
fi

# Power mode switching logic
mode_changed=0
if [[ $should_be_eco -eq 1 && "$current_mode" != "eco" ]]; then
    if switch_to_eco; then
        current_mode="eco"
        mode_changed=1
    fi
elif [[ $should_be_performance -eq 1 && "$current_mode" != "performance" ]]; then
    if switch_to_performance; then
        current_mode="performance"
        mode_changed=1
    fi
fi

# Update last activity timestamp
echo "$(date '+%Y-%m-%d %H:%M:%S')" > "$LAST_ACTIVITY_FILE"

# Output for Home Assistant sensor
echo "$current_mode"                                    # First line: current power mode
echo idle_time_minutes:$idle_minutes                    # Idle time in minutes
echo cpu_usage:$cpu_usage                              # CPU usage percentage
echo system_busy:$system_busy                          # System busy status
echo in_meeting:$in_meeting                            # Meeting status
echo mode_changed:$mode_changed                        # Whether mode changed this cycle
echo should_be_eco:$should_be_eco                      # Whether system should be in eco mode
echo should_be_performance:$should_be_performance      # Whether system should be in performance mode
echo last_check:$(date "+%Y-%m-%d %H:%M:%S")          # Timestamp