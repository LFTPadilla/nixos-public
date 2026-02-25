# Neovim Configuration

This Neovim setup is built using `lazy.nvim` as the plugin manager and uses **Space** as the leader key.

## General Keymaps

| Key | Action |
| :--- | :--- |
| `<leader>w` | Save file |
| `<leader>q` | Quit |
| `<leader>h` | Clear search highlight |
| `<C-h/j/k/l>` | Navigate between windows |
| `<C-\>` | Toggle floating terminal |

## File Exploration & Searching

| Key | Action |
| :--- | :--- |
| `<leader>ff` | **Telescope**: Find files (fuzzy) |
| `<leader>fg` | **Telescope**: Live grep (search text) |
| `<leader>fb` | **Telescope**: Find open buffers |
| `<leader>e` | **Yazi**: Open file explorer at current file |
| `<leader>cw` | **Yazi**: Open file explorer at working directory |

## LSP / Development

| Key | Action |
| :--- | :--- |
| `gd` | Go to definition |
| `gr` | Show references |
| `K` | Show hover documentation |
| `<leader>ca` | Code action |
| `<leader>rn` | Rename symbol |
| `<leader>lf` | Format file |
| `[d` / `]d` | Previous/Next diagnostic |

## Searching Tips
Telescope uses the **fzf** algorithm. You can use:
- `'word` to match exactly.
- `^word` for prefix match.
- `word$` for suffix match.
- `!word` to exclude results.
