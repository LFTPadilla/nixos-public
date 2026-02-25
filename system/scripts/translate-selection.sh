#!/run/current-system/sw/bin/bash
set -euo pipefail

# Translate currently selected text (Wayland + X11 compatible).
# Falls back to clipboard and then to prompt input.

exec /home/felipe/.dotfiles/system/scripts/translate.sh --selection
