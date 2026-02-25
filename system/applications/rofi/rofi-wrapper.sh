#!/usr/bin/env bash
# Rofi wrapper that applies dynamic theming based on the shared
# system theme state (light/dark), with GNOME color-scheme as a
# fallback when the state file is missing.

set -euo pipefail

# Source unified configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rofi-config.sh"

# Execute rofi with generated theme
exec rofi \
  -show-icons \
  -matching fuzzy \
  -cycle \
  -font "$ROFI_FONT" \
  -drun-display-format "{name}" \
  -window-format "{w}: {c} — {t}" \
  -theme-str "$(generate_theme_string)" \
  "$@"
