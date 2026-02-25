#!/usr/bin/env bash

# Function to start a tmuxinator project if not already running
start_project() {
    local name=$1
    if ! tmux has-session -t "$name" 2>/dev/null; then
        tmuxinator start "$name" --no-attach
    fi
}

# Start core projects
start_project "dotfiles"
start_project "vault"

# Use first argument for the 'work' project specifically if provided
if [ -n "$1" ]; then
    PROJECT="work"
    if ! tmux has-session -t "$PROJECT" 2>/dev/null; then
        tmuxinator start "$PROJECT" "$1" --no-attach
    fi
else
    start_project "work"
    PROJECT="dotfiles"
fi

# Attach to project if we are in a terminal and not already in tmux
if [ -t 0 ] && [ -z "$TMUX" ]; then
    tmux attach-session -t "$PROJECT"
fi
