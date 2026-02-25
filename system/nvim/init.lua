-- Set <Space> as leader early
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Bootstrap lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Core configuration (independent of plugins)
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Setup plugins
require("lazy").setup(require("plugins"), {
  ui = {
    border = "rounded",
  },
  checker = {
    enabled = true,
    notify = false,
  },
})

