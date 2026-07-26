#!/usr/bin/env bash
set -euo pipefail

# Cycle through cliphist entries and copy to clipboard.
# Usage: cliphist-cycle.sh next|prev

direction="${1:-next}"
if [ "$direction" != "next" ] && [ "$direction" != "prev" ]; then
  echo "Usage: $0 next|prev" >&2
  exit 1
fi

if ! command -v cliphist >/dev/null 2>&1 || ! command -v wl-copy >/dev/null 2>&1; then
  # Silent no-op if dependencies are missing; avoids noisy errors on login.
  exit 0
fi

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/cliphist"
mkdir -p "$STATE_DIR"
STATE_FILE="$STATE_DIR/current_id"

# Read current ID if present
current_id=""
if [ -f "$STATE_FILE" ]; then
  current_id="$(cat "$STATE_FILE" || true)"
fi

# Get list of entries. Keep the full line because `cliphist decode` expects
# the selected list entry on stdin; using only the numeric ID can paste the ID.
mapfile -t lines < <(cliphist list || true)
if [ "${#lines[@]}" -eq 0 ]; then
  exit 0
fi

ids=()
for line in "${lines[@]}"; do
  # First whitespace-separated field is the ID
  id="${line%%[[:space:]]*}"
  ids+=("$id")
done

count="${#ids[@]}"

# Find index of current_id in ids[]
current_index=0
if [ -n "$current_id" ]; then
  for i in "${!ids[@]}"; do
    if [ "${ids[$i]}" = "$current_id" ]; then
      current_index="$i"
      break
    fi
  done
fi

if [ "$direction" = "next" ]; then
  new_index=$(((current_index + 1) % count))
else
  new_index=$(((current_index - 1 + count) % count))
fi

new_id="${ids[$new_index]}"
new_line="${lines[$new_index]}"
printf '%s\n' "$new_id" >"$STATE_FILE"

printf '%s\n' "$new_line" | cliphist decode | wl-copy
