local M = {}

local function on_attach(client, bufnr)
  local bufmap = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
  end

  bufmap("n", "gd", vim.lsp.buf.definition, "Go to definition")
  bufmap("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
  bufmap("n", "gI", vim.lsp.buf.implementation, "Go to implementation")
  bufmap("n", "gr", vim.lsp.buf.references, "References")
  bufmap("n", "K", vim.lsp.buf.hover, "Hover")

  bufmap("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
  bufmap("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")

  bufmap("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
  bufmap("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
  bufmap("n", "<leader>ld", vim.diagnostic.open_float, "Line diagnostics")

  bufmap("n", "<leader>lf", function()
    vim.lsp.buf.format({ async = true })
  end, "Format buffer")

  vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
    vim.lsp.buf.format()
  end, {})
end

local function get_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
  if ok then
    capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
  end
  return capabilities
end

function M.setup()
  require("config.ui").setup_diagnostics()

  require("neodev").setup({})

  local servers = {
    lua_ls = {
      settings = {
        Lua = {
          workspace = { checkThirdParty = false },
          telemetry = { enable = false },
        },
      },
    },
    pyright = {},
    ts_ls = {},
    dockerls = {},
  }

  local mason = require("mason")
  local mason_lspconfig = require("mason-lspconfig")

  mason.setup({})
  mason_lspconfig.setup({
    ensure_installed = vim.tbl_keys(servers),
  })
  local capabilities = get_capabilities()

  for server_name, server_opts in pairs(servers) do
    local cfg = vim.tbl_deep_extend("force", server_opts, {
      on_attach = on_attach,
      capabilities = capabilities,
    })
    vim.lsp.config(server_name, cfg)
    vim.lsp.enable(server_name)
  end
end

return M
