#!/usr/bin/env bash
set -euo pipefail

# QR scan from screen region: capture, decode, copy to clipboard.
# Requires: flameshot, zbarimg (from zbar), xclip, notify-send

tmp_png="$(mktemp /tmp/qr-scan-XXXXXX.png)"
cleanup() { rm -f "$tmp_png" 2>/dev/null || true; }
trap cleanup EXIT

# Capture region to PNG via Flameshot (-r writes PNG to stdout)
if ! command -v flameshot >/dev/null; then
  notify-send "QR Scan" "flameshot not found"
  exit 1
fi
if ! command -v zbarimg >/dev/null; then
  notify-send "QR Scan" "zbarimg not found (install zbar)"
  exit 1
fi
if ! command -v xclip >/dev/null; then
  notify-send "QR Scan" "xclip not found"
  exit 1
fi

# If user cancels the selection, flameshot exits with non-zero or writes nothing
if ! flameshot gui -r >"$tmp_png"; then
  notify-send "QR Scan" "Canceled"
  exit 1
fi

if [ ! -s "$tmp_png" ]; then
  notify-send "QR Scan" "No image captured"
  exit 1
fi

# Decode QR(s); --raw prints content only
decoded="$(zbarimg -q --raw "$tmp_png" 2>/dev/null || true)"
if [ -z "$decoded" ]; then
  notify-send "QR Scan" "No QR code detected"
  exit 1
fi

# Copy to clipboard and notify
printf "%s" "$decoded" | xclip -selection clipboard
notify-send "QR Scan" "Copied to clipboard" -a qr-scan

# Also print to stdout for terminal runs
printf "%s\n" "$decoded"

