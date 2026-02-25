#!/usr/bin/env bash

set -euo pipefail

DEVICE="${1:-}"

pick_device() {
  local dev
  # Prefer explicitly passed device
  if [ -n "${DEVICE:-}" ] && [ -e "$DEVICE" ]; then
    printf '%s\n' "$DEVICE"
    return 0
  fi
  # Otherwise pick first non-loopback v4l2 device
  for dev in /dev/video[0-9]*; do
    [ -e "$dev" ] || continue
    if command -v udevadm >/dev/null 2>&1; then
      if udevadm info --query=property --name="$dev" 2>/dev/null | grep -q 'ID_V4L2_LOOPBACK=1'; then
        continue
      fi
    fi
    printf '%s\n' "$dev"
    return 0
  done
  return 1
}

DEVICE="$(pick_device || true)"

if [ -z "${DEVICE:-}" ]; then
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Webcam" "No video devices found"
  else
    printf 'No video devices found\n' >&2
  fi
  exit 1
fi

exec mpv --profile=low-latency --untimed --no-audio "av://v4l2:${DEVICE}"
