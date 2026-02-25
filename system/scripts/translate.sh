#!/run/current-system/sw/bin/bash
set -euo pipefail

# Quick translator (Wayland + X11 compatible)
# - Prompt: ./translate.sh
# - Translate selection/clipboard: ./translate.sh --selection
# - Translate clipboard: ./translate.sh --clipboard
#
# Defaults:
# - Source: auto
# - Target: es (if detected language == target, it auto-switches to en)

usage() {
  cat <<'EOF'
Usage:
  translate.sh                 # prompt with rofi
  translate.sh --selection     # translate primary selection (fallback: clipboard)
  translate.sh --clipboard     # translate clipboard
  translate.sh [TEXT...]       # translate provided text

Options:
  -f, --from CODE              Source language (default: auto)
  -t, --to CODE                Target language (default: es)
      --to-alt CODE            Alternate target used by smart mode (default: en)
      --no-smart               Disable auto-switch when text is already in target language
  -h, --help                   Show this help
EOF
}

ROFI_WRAPPER="${HOME}/.dotfiles/system/applications/rofi/rofi-wrapper.sh"
if [[ -x "$ROFI_WRAPPER" ]]; then
  ROFI=("$ROFI_WRAPPER")
else
  ROFI=(rofi)
fi

rofi_prompt() {
  local msg="${1:-}"
  if [[ -n "$msg" ]]; then
    "${ROFI[@]}" -dmenu -p "Translate:" -mesg "$msg" -theme-str 'window {width: 500px;}' || true
  else
    "${ROFI[@]}" -dmenu -p "Translate:" -theme-str 'window {width: 500px;}' || true
  fi
}

rofi_info() {
  local prompt="$1"
  local msg="$2"
  printf 'Close\n' | "${ROFI[@]}" -dmenu -p "$prompt" -mesg "$msg" -no-custom -theme-str 'window {width: 800px;}' >/dev/null || true
}

read_wl() {
  local selection="$1" # primary|clipboard
  local args=(--no-newline --type text)
  if [[ "$selection" == "primary" ]]; then
    args=(--primary "${args[@]}")
  fi

  if command -v wl-paste >/dev/null 2>&1; then
    wl-paste "${args[@]}" 2>/dev/null || true
  fi
}

read_xclip() {
  local selection="$1" # primary|clipboard
  if command -v xclip >/dev/null 2>&1; then
    xclip -o -selection "$selection" 2>/dev/null || true
  fi
}

active_window_class() {
  if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    return 0
  fi
  if ! command -v hyprctl >/dev/null 2>&1; then
    return 0
  fi
  hyprctl activewindow 2>/dev/null | awk -F': ' '/^[[:space:]]*class: /{print $2; exit}'
}

try_copy_selection() {
  if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    return 1
  fi
  if ! command -v hyprctl >/dev/null 2>&1; then
    return 1
  fi

  local class mod
  class="$(active_window_class)"
  mod="CTRL"
  case "$class" in
    kitty|Alacritty|foot|wezterm|org.wezfurlong.wezterm|org.gnome.Terminal|konsole)
      # Avoid SIGINT in terminals; they usually use Ctrl+Shift+C for copy.
      mod="CTRL_SHIFT"
      ;;
  esac

  hyprctl dispatch sendshortcut "${mod},C" >/dev/null 2>&1 || true
  return 0
}

read_selection_with_copy_fallback() {
  local primary clipboard_before clipboard_after

  primary="$(read_wl primary)"
  [[ -n "$primary" ]] || primary="$(read_xclip primary)"
  if [[ -n "$primary" ]]; then
    printf '%s' "$primary"
    return 0
  fi

  clipboard_before="$(read_wl clipboard)"
  [[ -n "$clipboard_before" ]] || clipboard_before="$(read_xclip clipboard)"

  if try_copy_selection; then
    sleep 0.15
  fi

  clipboard_after="$(read_wl clipboard)"
  [[ -n "$clipboard_after" ]] || clipboard_after="$(read_xclip clipboard)"

  if [[ -n "$clipboard_after" ]]; then
    printf '%s' "$clipboard_after"
    return 0
  fi

  printf '%s' "$clipboard_before"
}

copy_to_clipboard() {
  local text="$1"
  if command -v wl-copy >/dev/null 2>&1; then
    if printf '%s' "$text" | wl-copy --trim-newline 2>/dev/null; then
      return 0
    fi
  fi
  if command -v xclip >/dev/null 2>&1; then
    if printf '%s' "$text" | xclip -selection clipboard -in 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

translate_google() {
  local text="$1"
  local from="$2"
  local to="$3"

  if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required for translation" >&2
    return 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required for translation" >&2
    return 1
  fi

  local json
  json="$(
    curl -sS --max-time 10 --retry 2 --get \
      --data "client=gtx" \
      --data "sl=$from" \
      --data "tl=$to" \
      --data "dt=t" \
      --data-urlencode "q=$text" \
      "https://translate.googleapis.com/translate_a/single" \
      2>/dev/null || true
  )"

  local translation detected
  translation="$(printf '%s' "$json" | jq -r '.[0] | map(.[0]) | join("")' 2>/dev/null || true)"
  detected="$(printf '%s' "$json" | jq -r '.[2] // empty' 2>/dev/null || true)"

  [[ -n "$translation" && "$translation" != "null" ]] || return 1

  TRANSLATION="$translation"
  DETECTED="$detected"
}

mode="prompt"
from="${TRANSLATE_FROM:-auto}"
to="${TRANSLATE_TO:-es}"
to_alt="${TRANSLATE_TO_ALT:-en}"
smart=1
to_explicit=0
from_explicit=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --selection)
      mode="selection"
      shift
      ;;
    --clipboard)
      mode="clipboard"
      shift
      ;;
    -f|--from)
      from="${2:-}"
      from_explicit=1
      shift 2
      ;;
    -t|--to)
      to="${2:-}"
      to_explicit=1
      shift 2
      ;;
    --to-alt)
      to_alt="${2:-}"
      shift 2
      ;;
    --no-smart)
      smart=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

text=""
if [[ $# -gt 0 ]]; then
  mode="args"
  text="$*"
else
  case "$mode" in
    selection)
      text="$(read_selection_with_copy_fallback)"
      ;;
    clipboard)
      text="$(read_wl clipboard)"
      [[ -n "$text" ]] || text="$(read_xclip clipboard)"
      ;;
    prompt)
      text="$(rofi_prompt)"
      ;;
  esac
fi

if [[ -z "${text:-}" ]]; then
  # If selection/clipboard is empty, fall back to prompt.
  if [[ "$mode" != "prompt" ]]; then
    text="$(rofi_prompt "No selection found. Select text (or copy it) and try again — or type here.")"
  fi
fi

[[ -n "${text:-}" ]] || exit 0

TRANSLATION=""
DETECTED=""

if ! translate_google "$text" "$from" "$to"; then
  rofi_info "Error" "Translation failed. Check your internet connection."
  exit 1
fi

# Smart mode: if we're auto-detecting and the text is already in the target language,
# translate it to the alternate target instead.
if [[ "$smart" -eq 1 && "$from_explicit" -eq 0 && "$to_explicit" -eq 0 && "$from" == "auto" && -n "$DETECTED" && "$DETECTED" == "$to" ]]; then
  if translate_google "$text" "$from" "$to_alt"; then
    to="$to_alt"
  fi
fi

clipboard_msg=""
if copy_to_clipboard "$TRANSLATION"; then
  clipboard_msg=$'\n\n✓ Copied to clipboard'
else
  clipboard_msg=$'\n\nⓘ Clipboard helper not found (install wl-clipboard or xclip)'
fi

src_label="${DETECTED:-$from}"
rofi_info "Translation" "$(printf '%s\n\n%s → %s\n\nOriginal:\n%s%s\n' "$TRANSLATION" "$src_label" "$to" "$text" "$clipboard_msg")"
