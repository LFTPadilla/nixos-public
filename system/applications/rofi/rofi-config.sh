#!/usr/bin/env bash
# Unified Rofi Configuration
# Source this file in rofi scripts for consistent theming

# Font Configuration
export ROFI_FONT="${ROFI_FONT:-Monospace 15}"

# Dark Theme Colors (Catppuccin Mocha)
export ROFI_DARK_BG="#1e1e2e"
export ROFI_DARK_BG_ALT="#313244"
export ROFI_DARK_FG="#cdd6f4"
export ROFI_DARK_FG_ALT="#bac2de"
export ROFI_DARK_ACCENT="#89b4fa"
export ROFI_DARK_ACCENT2="#cba6f7"
export ROFI_DARK_BORDER="#45475a"

# Light Theme Colors (Catppuccin Latte)
export ROFI_LIGHT_BG="#eff1f5"
export ROFI_LIGHT_BG_ALT="#e6e9ef"
export ROFI_LIGHT_FG="#4c4f69"
export ROFI_LIGHT_FG_ALT="#5c5f77"
export ROFI_LIGHT_ACCENT="#1e66f5"
export ROFI_LIGHT_ACCENT2="#8839ef"
export ROFI_LIGHT_BORDER="#acb0be"

# Layout Configuration
export ROFI_WIDTH="${ROFI_WIDTH:-800px}"
export ROFI_BORDER_WIDTH="${ROFI_BORDER_WIDTH:-2px}"
export ROFI_BORDER_RADIUS="${ROFI_BORDER_RADIUS:-16px}"
export ROFI_PADDING="${ROFI_PADDING:-16px}"
export ROFI_SPACING="${ROFI_SPACING:-12px}"
export ROFI_INPUT_BORDER_RADIUS="${ROFI_INPUT_BORDER_RADIUS:-10px}"
export ROFI_INPUT_PADDING="${ROFI_INPUT_PADDING:-12px 16px}"
export ROFI_ELEMENT_BORDER_RADIUS="${ROFI_ELEMENT_BORDER_RADIUS:-8px}"
export ROFI_ELEMENT_PADDING="${ROFI_ELEMENT_PADDING:-10px 12px}"
export ROFI_ELEMENT_SPACING="${ROFI_ELEMENT_SPACING:-12px}"
export ROFI_ICON_SIZE="${ROFI_ICON_SIZE:-28px}"
export ROFI_LISTVIEW_LINES="${ROFI_LISTVIEW_LINES:-10}"
export ROFI_LISTVIEW_SPACING="${ROFI_LISTVIEW_SPACING:-4px}"

# Detect current theme mode
detect_theme() {
    local CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
    local THEME_STATE_FILE="${CONFIG_DIR}/system-theme"

    # Highest priority override (useful for debugging)
    case "${ROFI_THEME_MODE:-}" in
        light|dark) echo "${ROFI_THEME_MODE}"; return 0 ;;
    esac

    local file_mode=""
    if [ -f "$THEME_STATE_FILE" ]; then
        file_mode="$(cat "$THEME_STATE_FILE" | tr -d '\r' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' || true)"
    fi

    # Check file mode first (works for Hyprland and other WMs)
    [[ "$file_mode" == "dark" ]] && echo "dark" && return 0
    [[ "$file_mode" == "light" ]] && echo "light" && return 0

    # Fallback to gsettings when available (GNOME/GTK theme)
    if command -v gsettings >/dev/null 2>&1; then
        local scheme gtk_theme
        scheme="$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'" | tr -d '\r' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' || true)"
        gtk_theme="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'" | tr -d '\r' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' || true)"
        [[ "$scheme" == "prefer-dark" ]] && echo "dark" && return 0
        [[ -n "$gtk_theme" && "$gtk_theme" =~ [dD]ark ]] && echo "dark" && return 0
        [[ "$scheme" == "prefer-light" ]] && echo "light" && return 0
    fi

    # Default to dark theme
    echo "dark"
}

# Export current theme mode
export ROFI_CURRENT_THEME=$(detect_theme)

# Set theme-specific colors based on detected theme
if [ "$ROFI_CURRENT_THEME" = "light" ]; then
    export ROFI_BG="$ROFI_LIGHT_BG"
    export ROFI_BG_ALT="$ROFI_LIGHT_BG_ALT"
    export ROFI_FG="$ROFI_LIGHT_FG"
    export ROFI_FG_ALT="$ROFI_LIGHT_FG_ALT"
    export ROFI_ACCENT="$ROFI_LIGHT_ACCENT"
    export ROFI_ACCENT2="$ROFI_LIGHT_ACCENT2"
    export ROFI_BORDER="$ROFI_LIGHT_BORDER"
else
    export ROFI_BG="$ROFI_DARK_BG"
    export ROFI_BG_ALT="$ROFI_DARK_BG_ALT"
    export ROFI_FG="$ROFI_DARK_FG"
    export ROFI_FG_ALT="$ROFI_DARK_FG_ALT"
    export ROFI_ACCENT="$ROFI_DARK_ACCENT"
    export ROFI_ACCENT2="$ROFI_DARK_ACCENT2"
    export ROFI_BORDER="$ROFI_DARK_BORDER"
fi

# Function to generate inline theme string
generate_theme_string() {
    cat <<EOF
* {
  bg: $ROFI_BG;
  bg-alt: $ROFI_BG_ALT;
  fg: $ROFI_FG;
  fg-alt: $ROFI_FG_ALT;
  accent: $ROFI_ACCENT;
  accent2: $ROFI_ACCENT2;
  border: $ROFI_BORDER;

  background-color: transparent;
  text-color: @fg;
  font: "$ROFI_FONT";
}

window {
  width: $ROFI_WIDTH;
  background-color: @bg;
  border: $ROFI_BORDER_WIDTH solid;
  border-color: @border;
  border-radius: $ROFI_BORDER_RADIUS;
  padding: $ROFI_PADDING;
}

mainbox {
  background-color: transparent;
  spacing: $ROFI_SPACING;
  children: [inputbar, listview];
}

inputbar {
  background-color: @bg-alt;
  border-radius: $ROFI_INPUT_BORDER_RADIUS;
  padding: $ROFI_INPUT_PADDING;
  children: [entry];
}

entry {
  background-color: transparent;
  text-color: @fg;
  placeholder: "Type to search...";
  placeholder-color: @fg-alt;
  cursor: text;
}

listview {
  background-color: transparent;
  lines: $ROFI_LISTVIEW_LINES;
  spacing: $ROFI_LISTVIEW_SPACING;
  scrollbar: false;
}

element {
  background-color: transparent;
  text-color: @fg;
  border-radius: $ROFI_ELEMENT_BORDER_RADIUS;
  padding: $ROFI_ELEMENT_PADDING;
  spacing: $ROFI_ELEMENT_SPACING;
  orientation: horizontal;
}

element selected {
  background-color: @accent;
  text-color: @bg;
}

element-icon {
  size: $ROFI_ICON_SIZE;
  background-color: transparent;
}

element-text {
  background-color: transparent;
  text-color: inherit;
  vertical-align: 0.5;
}
EOF
}
