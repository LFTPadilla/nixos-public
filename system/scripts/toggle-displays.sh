#!/usr/bin/env bash

# Cycle common display layouts in Hyprland (extend, internal, external, mirror)
# to mimic the GNOME Super+P behaviour.
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
STATE_FILE="${STATE_DIR}/display-mode"
mkdir -p "${STATE_DIR}"

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Display layout" "$1"
  fi
}

mode_for_monitor() {
  local name="$1"
  local role="$2" # internal|external

  # Known-good defaults for Felipe's setup (DP-1 external, eDP-1 laptop).
  if [[ "$role" == "external" && "$name" == "DP-1" ]]; then
    echo "2560x1440@165"
    return 0
  fi
  if [[ "$role" == "internal" && "$name" =~ ^(eDP|LVDS|DSI) ]]; then
    echo "1920x1080@144"
    return 0
  fi

  # Fallback to preferred mode for other hardware.
  echo "preferred"
}

if ! command -v hyprctl >/dev/null 2>&1; then
  echo "hyprctl is required to toggle displays" >&2
  exit 1
fi

monitors_json="$(hyprctl monitors all -j 2>/dev/null || hyprctl monitors -j)" || {
  notify "Unable to read Hyprland monitors (is Hyprland running?)"
  exit 1
}

if [[ -z "${monitors_json}" || "${monitors_json}" == "[]" ]]; then
  notify "No monitors reported by hyprctl"
  exit 1
fi

# Try to auto-detect the internal panel and first external output.
internal_monitor="$(jq -r '.[] | select(.name | test("(?i)eDP|LVDS")) | .name' <<<"${monitors_json}" | head -n 1)"
external_monitor="$(jq -r --arg internal "${internal_monitor}" '.[] | select(.name != $internal) | .name' <<<"${monitors_json}" | head -n 1)"

# Allow manual overrides via env vars if detection fails.
internal_monitor="${internal_monitor:-${DEFAULT_INTERNAL_MONITOR:-}}"
external_monitor="${external_monitor:-${DEFAULT_EXTERNAL_MONITOR:-}}"

has_internal=false
if [[ -n "${internal_monitor}" ]]; then
  has_internal=true
fi

external_connected=false
if [[ -n "${external_monitor}" ]]; then
  if jq -e --arg name "${external_monitor}" '.[] | select(.name == $name) | select((.status // "connected") != "disconnected")' <<<"${monitors_json}" >/dev/null; then
    external_connected=true
  fi
fi

if ! ${has_internal} && ! ${external_connected}; then
  notify "No connected monitors detected"
  exit 1
fi

if ${has_internal} && ${external_connected}; then
  available_modes=("extend" "internal" "external" "mirror")
elif ${external_connected}; then
  available_modes=("external")
else
  available_modes=("internal")
fi

current_mode="$(cat "${STATE_FILE}" 2>/dev/null || true)"
next_mode="${available_modes[0]}"
for i in "${!available_modes[@]}"; do
  if [[ "${available_modes[$i]}" == "${current_mode}" ]]; then
    next_mode="${available_modes[$(((i + 1) % ${#available_modes[@]}))]}"
    break
  fi
done

case "${next_mode}" in
  extend)
    external_mode="$(mode_for_monitor "${external_monitor}" external)"
    internal_mode="$(mode_for_monitor "${internal_monitor}" internal)"
    hyprctl keyword monitor "${external_monitor},${external_mode},0x0,1"
    hyprctl keyword monitor "${internal_monitor},${internal_mode},auto,1"
    notify "Extend (external + internal)"
    ;;
  internal)
    if [[ -n "${external_monitor}" ]]; then
      hyprctl keyword monitor "${external_monitor},disable" >/dev/null 2>&1 || true
    fi
    internal_mode="$(mode_for_monitor "${internal_monitor}" internal)"
    hyprctl keyword monitor "${internal_monitor},${internal_mode},0x0,1"
    notify "Laptop/internal only"
    ;;
  external)
    if [[ -n "${internal_monitor}" ]]; then
      hyprctl keyword monitor "${internal_monitor},disable" >/dev/null 2>&1 || true
    fi
    external_mode="$(mode_for_monitor "${external_monitor}" external)"
    hyprctl keyword monitor "${external_monitor},${external_mode},0x0,1"
    notify "External only"
    ;;
  mirror)
    internal_mode="$(mode_for_monitor "${internal_monitor}" internal)"
    hyprctl keyword monitor "${internal_monitor},${internal_mode},0x0,1"
    hyprctl keyword monitor "${external_monitor},${internal_mode},auto,1,mirror,${internal_monitor}"
    notify "Mirror displays"
    ;;
  *)
    notify "Unknown display mode: ${next_mode}"
    exit 1
    ;;
esac

if [[ -x "$HOME/.local/bin/hypr-pin-workspaces" ]]; then
  "$HOME/.local/bin/hypr-pin-workspaces" >/dev/null 2>&1 || true
fi

echo "${next_mode}" >"${STATE_FILE}"
