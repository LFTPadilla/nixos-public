#!/usr/bin/env bash

set -euo pipefail

# Simple DDC/CI monitor scheduler
# - Adjusts brightness and RGB gains based on local time
# - Targets monitors detected by ddcutil; optionally filter by model name

# Schedule (24h clock)
MORNING_START=7     # 07:00–11:59
AFTERNOON_START=12  # 12:00–17:59
NIGHT_START=18      # 18:00–06:59

# Levels
MORNING_BRIGHT=100
AFTERNOON_BRIGHT=30
NIGHT_BRIGHT=1

# Color profiles (RGB gains). Many monitors accept 0..100 for gains.
# Note: Some monitors require a specific color preset (e.g., "User") to allow RGB changes.
# If RGB writes fail, brightness will still be applied.
MORNING_RGB_R=100; MORNING_RGB_G=100; MORNING_RGB_B=100
AFTERNOON_RGB_R=100; AFTERNOON_RGB_G=100; AFTERNOON_RGB_B=100
NIGHT_RGB_R=100; NIGHT_RGB_G=0;   NIGHT_RGB_B=0

# Optional: filter monitors by model substring (leave empty to apply to all)
TARGET_MODEL=${TARGET_MODEL:-"NZXT"}

# Extra flags for ddcutil. Disable dynamic sleep for snappier writes on some displays.
DDC_FLAGS=(--disable-dynamic-sleep)

log() {
  echo "[ddc-schedule] $*" >&2
}

detect_displays() {
  # Prints display numbers detected by ddcutil, filtered by model if TARGET_MODEL is set
  if ! command -v ddcutil >/dev/null 2>&1; then
    log "ddcutil not found in PATH"
    return 1
  fi

  # Parse ddcutil detect output to map Display N blocks to Model lines
  ddcutil detect 2>/dev/null | awk -v model_substr="$TARGET_MODEL" '
    BEGIN { d = ""; match_model = (length(model_substr) == 0) }
    /^Display [0-9]+/ { d = $2; match_model = (length(model_substr) == 0) }
    /Model:/ {
      if (length(model_substr) > 0) {
        if (index($0, model_substr) > 0) match_model = 1
      }
    }
    /^$/ { if (d != "" && match_model) print d; d = "" }
    END { if (d != "" && match_model) print d }
  '
}

apply_settings() {
  local display="$1" bright="$2" r="$3" g="$4" b="$5"

  # 0x10 = Brightness, 0x16 = Red gain, 0x18 = Green gain, 0x1A = Blue gain
  if ! ddcutil "${DDC_FLAGS[@]}" --display "$display" setvcp 10 "$bright" >/dev/null 2>&1; then
    log "Failed to set brightness on display $display"
  else
    log "Set brightness=$bright on display $display"
  fi

  # Try to set RGB gains; ignore failures if monitor disallows it
  if ddcutil "${DDC_FLAGS[@]}" --display "$display" setvcp 16 "$r" >/dev/null 2>&1; then
    log "Set R=$r on display $display"
  else
    log "Skipping R gain on display $display (unsupported?)"
  fi

  if ddcutil "${DDC_FLAGS[@]}" --display "$display" setvcp 18 "$g" >/dev/null 2>&1; then
    log "Set G=$g on display $display"
  else
    log "Skipping G gain on display $display (unsupported?)"
  fi

  if ddcutil "${DDC_FLAGS[@]}" --display "$display" setvcp 1A "$b" >/dev/null 2>&1; then
    log "Set B=$b on display $display"
  else
    log "Skipping B gain on display $display (unsupported?)"
  fi
}

set_internal_brightness() {
  local bright="$1"
  if command -v brightnessctl >/dev/null 2>&1; then
    if brightnessctl --machine-readable --class backlight set "${bright}%" >/dev/null 2>&1; then
      log "Set internal backlight to ${bright}% via brightnessctl"
      return 0
    fi
  fi
  # Fallback to sysfs if brightnessctl is unavailable or failed
  local dev
  for dev in /sys/class/backlight/*; do
    [[ -d "$dev" ]] || continue
    local max cur target
    if [[ -r "$dev/max_brightness" ]]; then
      max=$(<"$dev/max_brightness")
      # target = round(max * bright / 100)
      target=$(( (max * bright + 50) / 100 ))
      if [[ -w "$dev/brightness" ]]; then
        echo "$target" >"$dev/brightness" 2>/dev/null || true
        log "Set internal backlight on $(basename "$dev") to ${bright}% (~${target}/${max})"
      fi
    fi
  done
}

configure_gnome_night_light() {
  # Adjust GNOME Night Light if available. No-op if GNOME/dconf absent.
  local enabled="$1" temp="$2"
  if command -v gsettings >/dev/null 2>&1; then
    if [[ "$enabled" == "true" ]]; then
      gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true || true
      [[ -n "$temp" ]] && gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature "$temp" || true
      # Use manual schedule (we control timing). Disable automatic schedule.
      gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic false || true
      log "Enabled GNOME Night Light (temp=${temp:-unchanged})"
    else
      gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled false || true
      log "Disabled GNOME Night Light"
    fi
  fi
}

main() {
  # Determine period by hour
  local hour
  hour=$(date +%H)
  # remove leading zero for numeric comparison
  hour=$((10#$hour))

  local bright r g b label int_bright night_light
  night_light=false

  if (( hour == 17 )); then
    # 5 PM override:
    # - External monitors: brightness 1, RGB R=100 G=70 B=40
    # - Laptop internal panel: brightness 20%
    label="17h"
    bright=1; r=100; g=70; b=40; int_bright=20; night_light=false
  elif (( hour >= MORNING_START && hour < AFTERNOON_START )); then
    bright=$MORNING_BRIGHT; r=$MORNING_RGB_R; g=$MORNING_RGB_G; b=$MORNING_RGB_B; label="morning"; int_bright=$bright; night_light=false
  elif (( hour >= AFTERNOON_START && hour < NIGHT_START )); then
    bright=$AFTERNOON_BRIGHT; r=$AFTERNOON_RGB_R; g=$AFTERNOON_RGB_G; b=$AFTERNOON_RGB_B; label="afternoon"; int_bright=$bright; night_light=false
  else
    bright=$NIGHT_BRIGHT; r=$NIGHT_RGB_R; g=$NIGHT_RGB_G; b=$NIGHT_RGB_B; label="night"; int_bright=$bright; night_light=true
  fi

  log "Applying profile: $label (ext brightness=$bright, rgb=$r/$g/$b, int brightness=${int_bright:-$bright})"

  mapfile -t displays < <(detect_displays)
  if ((${#displays[@]} == 0)); then
    log "No matching DDC displays found"
    exit 0
  fi

  for d in "${displays[@]}"; do
    apply_settings "$d" "$bright" "$r" "$g" "$b"
  done

  # Also apply to the laptop's internal panel via backlight interface
  set_internal_brightness "$int_bright"

  # Drive GNOME Night Light for integrated display color warmth
  if [[ "$night_light" == "true" ]]; then
    # 1000–10000 range; 1700 is very warm
    configure_gnome_night_light true 1700
  else
    configure_gnome_night_light false ""
  fi
}

main "$@"
