#!/usr/bin/env bash
# Smart tmux attach for Kitty — avoids nesting and prefers existing sessions.

# If tmux is unavailable, fall back to the normal shell.
if ! command -v tmux >/dev/null 2>&1; then
  exec "${SHELL:-/bin/zsh}"
fi

# Already inside tmux? Just start a plain shell.
if [[ -n "${TMUX:-}" ]]; then
    exec "${SHELL:-zsh}"
fi

# Try existing sessions in priority order.
for session in personal work; do
    if tmux has-session -t "$session" 2>/dev/null; then
        exec tmux attach-session -t "$session"
    fi
done

# Any other detached session available?
first_session=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | head -n1)
if [[ -n "$first_session" ]]; then
    exec tmux attach-session -t "$first_session"
fi

# Nothing running — start a fresh main session.
exec tmux new-session -s main
