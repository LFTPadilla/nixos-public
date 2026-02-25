local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Better window navigation
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- Save / quit
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save", silent = true })
map("n", "<leader>x", "<cmd>w | bd<cr>", { desc = "Save and Close", silent = true })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit", silent = true })

-- Clear search highlight
map("n", "<leader>h", "<cmd>nohlsearch<cr>", { desc = "Clear search", silent = true })

