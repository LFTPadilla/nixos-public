# Tmux Shortcuts (default + custom)

Source: `users/felipe/home-modules/shell.nix` (`programs.tmux.extraConfig`).  
Reload: `Prefix + r` (sources `~/.config/tmux/tmux.conf` inside tmux).

## Highlights
- Smart pane nav: `Ctrl-h/j/k/l` switches panes but passes through in `nvim`, `fzf`, `yazi`, etc.
- Sessionizer: `Prefix + Ctrl-f` picks a directory → jumps/creates a session.
- Popups: `Prefix + T` opens `btop`, `Prefix + Y` opens `yazi`.
- Clipboard: mouse drag-select copies on release.

## Prefixes
- Primary: `` ` `` (Backtick) - Press twice to send a literal backtick.
- Secondary: `Ctrl-Space` and `Ctrl-b`

## Pane focus & movement
- Default tmux: `Prefix + Arrow keys` moves between panes; `Prefix + q` shows pane numbers to jump; `Prefix + o` cycles panes.
- Custom: `Prefix + h` / `j` / `k` / `l` move left/down/up/right.
- Smart nav: `Ctrl-h` / `Ctrl-j` / `Ctrl-k` / `Ctrl-l` (no prefix) move left/down/up/right (passes through in `nvim`, `fzf`, `yazi`, etc.).
- Windows: `Prefix + Ctrl-h` / `Prefix + Ctrl-l` go to previous/next window.

## Pane resizing
- Custom (repeatable): `Prefix + H` / `J` / `K` / `L` shrink/expand 5 cells.

## Splits (current pane directory)
- Vertical: `Prefix + "` (default) or `Prefix + -` (custom)
- Horizontal: `Prefix + %` (default) or `Prefix + \` or `Prefix + |` (custom)

## Windows
- New window: `Prefix + c`
- Close: `Prefix + x` kills pane; `Prefix + X` kills window (`Prefix + &` default still works)
- Rename: `Prefix + ,` (default)
- Next/previous: `Prefix + n` / `Prefix + p` (default)
- Jump: `Prefix + w` (choose-window menu) or `Prefix + [0-9]` (default)

## Sessions
- List/switch: `Prefix + s` (choose-tree)
- Detach: `Prefix + d` (default)
- Rename session: `Prefix + $` (default)
- Sessionizer: `Prefix + Ctrl-f` → pick a directory and jump/create a session for it.

## Copy & clipboard (vi mode)
- Enter copy mode: `Prefix + [`; paste: `Prefix + ]` (default)
- Selections: `v` begin selection; `r` rectangle toggle.
- Copy: `y` copies to system clipboard (`wl-copy`, fallback `xclip`).
- Mouse: drag-select copies to clipboard on release.
- Faster scroll in copy mode: `J`/`K` move 10 lines; `Ctrl-d`/`Ctrl-u` move 20 lines.

## Quick command windows
- `Prefix + g`: new window running `git status`
- `Prefix + t`: new window running `btop`
- `Prefix + y`: new window running `yazi`
- Popups: `Prefix + T` (`btop`) and `Prefix + Y` (`yazi`)

## FZF helpers
- URL picker: `Prefix + u` → grab URLs from scrollback and open.
- Switchers (fzf):
  - `Prefix + f`: sessions + windows + panes
  - `Prefix + S`: sessions
  - `Prefix + W`: windows
  - `Prefix + P`: panes

## Status & quality-of-life
- Status bar on top (Catppuccin mocha). Right side: git status + time + CPU + battery + prefix indicator.
- Pane borders show index, command, and a shortened path.
- Mouse enabled; history 50k; windows/panes start at 1 with auto-renumber.
- Terminfo: `tmux-256color`, truecolor advertised, `COLORTERM=truecolor`.

## Restore/automation
- Tmuxinator: Declarative session management via `~/.config/tmuxinator/*.yml`.
- `tmux-init`: Custom script (`system/scripts/tmux-init.sh`) to auto-launch `dotfiles`, `brain`, and `work` sessions.
- Integrated into `workspace-startup` to initialize environments on login.
- Continuum + Resurrect enabled; auto-save every 15 minutes and restore on attach.

## TPM Plugins (Tmux Plugin Manager)

Additional plugins installed via TPM for enhanced functionality.

### Installation
```bash
# Install TPM (first time only)
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Inside tmux, install plugins
Prefix + I  (Ctrl-Space then Shift+i)

# Update plugins
Prefix + U

# Uninstall removed plugins
Prefix + alt + u
```

### Installed Plugins

**tmux-sessionx** - Advanced session manager
- Keybinding: `Prefix + o`
- Features: Fuzzy search, preview, zoxide integration
- Shows session tree with directory paths
- Creates new sessions from any directory

**tmux-thumbs** - Copy/paste with keyboard hints
- Keybinding: `Prefix + Space`
- Features: Vimium-style hints for text selection
- Highlights URLs, file paths, git SHAs, IP addresses
- Press highlighted key to copy to clipboard

**tmux-floax** - Floating terminal popup
- Keybinding: `Prefix + F` (Shift+f)
- Features: Dropdown-style terminal overlay
- 80% width/height, magenta border
- Changes to current pane's directory

**sainnhe/tmux-fzf** - Comprehensive FZF menus
- Keybinding: `Prefix + Ctrl-f`
- Features: All tmux operations via FZF
- Session/window/pane management
- Keybinding browser, clipboard history

### Theme Configuration

The status bar uses the **Catppuccin Mocha** theme with powerline separators.

**Catppuccin Settings:**
- Window separators: `` (powerline rounded)
- Status modules: session (left), directory + date/time (right)
- Window display: number + name, zoom indicator
- Auto-styled with Catppuccin colors

**Customization:**
All theme settings are in `users/felipe/home-modules/shell.nix` under the `@catppuccin_*` variables. The plugin auto-generates the status bar styling - avoid manually setting `status-style`, `window-status-format`, etc. as they override the plugin.

## Requirements
- `tmux` ≥ 3.2, `fzf`, `wl-copy` or `xclip`; optional: `git`, `btop`, `yazi`, `zoxide`, `neofetch`.
- **TPM**: Tmux Plugin Manager for plugin support
- **Nerd Font**: JetBrains Mono Nerd Font for powerline separators
