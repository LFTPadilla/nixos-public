#!/usr/bin/env bash

# Rofi file browser script
# Usage: rofi -show file-browser -modi "file-browser:~/.dotfiles/system/applications/rofi/file-browser.sh"

# Function to handle directory navigation
navigate() {
    # Strip icon and trailing slash
    item=$(echo "$1" | sed 's/^[^ ]* //; s/\/$//')

    if [[ "$item" == ".." ]]; then
        # Go up one directory
        cd ..
        exec "$0" "$(pwd)"
    elif [[ -d "$item" ]]; then
        # Enter directory and get full path
        cd "$item"
        full_path=$(pwd)
        # Open directory with the default file manager in a fully detached way
        # Prefer gio on GNOME; fall back to xdg-open. Use setsid to detach
        if command -v gio >/dev/null 2>&1; then
            setsid -f gio open "$full_path" >/dev/null 2>&1 || true
        elif command -v xdg-open >/dev/null 2>&1; then
            setsid -f xdg-open "$full_path" >/dev/null 2>&1 || true
        else
            # If no opener is available, continue browsing inside rofi
            exec "$0" "$full_path"
        fi
    elif [[ -f "$item" ]]; then
        # Open file with default application
        if command -v gio >/dev/null 2>&1; then
            setsid -f gio open "$item" >/dev/null 2>&1 || true
        elif command -v xdg-open >/dev/null 2>&1; then
            setsid -f xdg-open "$item" >/dev/null 2>&1 || true
        elif command -v open >/dev/null 2>&1; then
            setsid -f open "$item" >/dev/null 2>&1 || true
        else
            # Fallback to text editor for text files
            if file "$item" | grep -q "text"; then
                setsid -f kitty -e nvim "$item" >/dev/null 2>&1 || true
            fi
        fi
    fi
}

# Check if this is a rofi callback with selection (ROFI_RETV=1 means item selected)
if [ -n "${ROFI_RETV}" ] && [ "${ROFI_RETV}" = "1" ] && [ -n "$1" ]; then
    navigate "$1"
    exit 0
fi

# Handle initial directory argument or default to current directory
if [ -n "$ROFI_DATA" ] && [ -d "$ROFI_DATA" ]; then
    # Use persistent data for current directory across invocations
    cd "$ROFI_DATA"
elif [ -n "$1" ] && [ -d "$1" ]; then
    # Initial invocation with directory argument
    cd "$1"
elif [ -z "$1" ]; then
    # No argument, start from home
    cd "$HOME"
fi

# Get current directory
current_dir=$(pwd)

# Show current directory in prompt
echo -e "\0prompt\x1f📁 $current_dir"

# Always show parent directory option unless we're at root
if [[ "$current_dir" != "/" ]]; then
    echo "../"
fi

# Function to add icon based on file type
add_icon() {
    local item="$1"
    if [[ -d "$item" ]]; then
        echo "📁 $item/"
    else
        # Add appropriate icon based on file type
        if [[ "$item" == *.txt ]] || [[ "$item" == *.md ]]; then
            echo "📄 $item"
        elif [[ "$item" == *.pdf ]]; then
            echo "📔 $item"
        elif [[ "$item" == *.jpg ]] || [[ "$item" == *.png ]] || [[ "$item" == *.gif ]] || [[ "$item" == *.webp ]]; then
            echo "🖼️  $item"
        elif [[ "$item" == *.mp4 ]] || [[ "$item" == *.mkv ]] || [[ "$item" == *.avi ]]; then
            echo "🎬 $item"
        elif [[ "$item" == *.mp3 ]] || [[ "$item" == *.wav ]] || [[ "$item" == *.flac ]]; then
            echo "🎵 $item"
        elif [[ -x "$item" ]]; then
            echo "⚙️  $item"
        else
            echo "📄 $item"
        fi
    fi
}

# List directories first, then files
# Use fd if available for better performance, otherwise fall back to find
if command -v fd >/dev/null 2>&1; then
    # Use fd (faster alternative to find)
    {
        fd -d 1 -H -t d --color never 2>/dev/null | sort
        fd -d 1 -H -t f --color never 2>/dev/null | sort
    } | while read -r item; do
        add_icon "$item"
    done
else
    # Fallback to find
    {
        find . -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort
        find . -maxdepth 1 -mindepth 1 -type f 2>/dev/null | sort
    } | while read -r item; do
        # Skip current directory
        if [[ "$item" == "." ]]; then
            continue
        fi
        # Remove leading ./
        item=${item#./}
        add_icon "$item"
    done
fi
