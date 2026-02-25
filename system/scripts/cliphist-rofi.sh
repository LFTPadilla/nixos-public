#!/usr/bin/env bash
set -euo pipefail

# Rofi interface for cliphist: pick an entry from history and
# copy it to the Wayland clipboard.
# Supports pinning frequently used entries with Alt+P.

if ! command -v cliphist >/dev/null 2>&1 || ! command -v wl-copy >/dev/null 2>&1; then
  # Silent no-op if dependencies are missing.
  exit 0
fi

ROFI_WRAPPER="$HOME/.dotfiles/system/applications/rofi/rofi-wrapper.sh"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/cliphist"
PINNED_DIR="$STATE_DIR/pinned"

mkdir -p "$PINNED_DIR"

if [ -x "$ROFI_WRAPPER" ]; then
  # Use themed wrapper if available
  chooser=("$ROFI_WRAPPER" -dmenu -p "Clipboard" -kb-custom-1 "Alt-p")
else
  chooser=(rofi -dmenu -p "Clipboard" -kb-custom-1 "Alt-p")
fi

menu_lines=()
entry_types=()
entry_ids=()

# Pinned entries first (starred)
if [ -d "$PINNED_DIR" ]; then
  while IFS= read -r file; do
    [ -f "$file" ] || continue
    hash="$(basename "$file")"
    preview="$(head -c 512 "$file" | tr '\n' ' ')"
    # Truncate to keep menu tidy
    preview="${preview:0:80}"
    line="★ $preview"
    menu_lines+=("$line")
    entry_types+=("pin")
    entry_ids+=("$hash")
  done < <(find "$PINNED_DIR" -type f -maxdepth 1 2>/dev/null | sort)
fi

# History entries from cliphist
while IFS= read -r line; do
  [ -n "$line" ] || continue
  id="${line%% *}"
  preview="${line#"$id "}"
  menu_lines+=("$preview")
  entry_types+=("hist")
  entry_ids+=("$id")
done < <(cliphist list || true)

if [ "${#menu_lines[@]}" -eq 0 ]; then
  exit 0
fi

selection="$(printf '%s\n' "${menu_lines[@]}" | "${chooser[@]}")"
status=$?

if [ -z "${selection:-}" ]; then
  exit 0
fi

# Find the selected entry metadata
index=-1
for i in "${!menu_lines[@]}"; do
  if [ "${menu_lines[$i]}" = "$selection" ]; then
    index="$i"
    break
  fi
done

if [ "$index" -lt 0 ]; then
  exit 0
fi

etype="${entry_types[$index]}"
eid="${entry_ids[$index]}"

pin_file="$PINNED_DIR/$eid"

paste_from_history() {
  cliphist decode "$eid" | wl-copy
}

paste_from_pinned() {
  cat "$pin_file" | wl-copy
}

toggle_pin_for_history() {
  content="$(cliphist decode "$eid" || true)"
  [ -n "$content" ] || return 0

  if command -v sha256sum >/dev/null 2>&1; then
    hash="$(printf '%s' "$content" | sha256sum | awk '{print $1}')"
  else
    # Fallback: simple checksum using md5sum/shasum if available
    if command -v md5sum >/dev/null 2>&1; then
      hash="$(printf '%s' "$content" | md5sum | awk '{print $1}')"
    elif command -v shasum >/dev/null 2>&1; then
      hash="$(printf '%s' "$content" | shasum | awk '{print $1}')"
    else
      return 0
    fi
  fi

  pin_file_local="$PINNED_DIR/$hash"
  if [ -f "$pin_file_local" ]; then
    rm -f "$pin_file_local"
  else
    printf '%s' "$content" >"$pin_file_local"
  fi

  printf '%s' "$content" | wl-copy
}

toggle_pin_for_pinned() {
  if [ -f "$pin_file" ]; then
    content="$(cat "$pin_file")"
    rm -f "$pin_file"
    printf '%s' "$content" | wl-copy
  fi
}

case "$status" in
  0)
    # Enter: paste only
    if [ "$etype" = "hist" ]; then
      paste_from_history
    else
      paste_from_pinned
    fi
    ;;
  10)
    # Alt+P: pin/unpin + paste
    if [ "$etype" = "hist" ]; then
      toggle_pin_for_history
    else
      toggle_pin_for_pinned
    fi
    ;;
  *)
    exit 0
    ;;
esac
