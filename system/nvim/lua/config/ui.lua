local M = {}

function M.setup_colorscheme()
  vim.cmd.colorscheme("tokyonight")
end

function M.setup_lualine()
  require("lualine").setup({
    options = {
      theme = "tokyonight",
      icons_enabled = true,
      section_separators = "",
      component_separators = "",
    },
  })
end

function M.setup_diagnostics()
  local signs = {
    Error = " ",
    Warn = " ",
    Hint = "󰌵 ",
    Info = " ",
  }

  for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
  end

  vim.diagnostic.config({
    virtual_text = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
      border = "rounded",
    },
  })
end

return M

