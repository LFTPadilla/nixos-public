local M = {}

function M.setup()
  local ts = require("nvim-treesitter")
  
  ts.setup({
    -- highlight and indent are now largely handled by nvim itself or 
    -- defaults in the new nvim-treesitter
  })

  -- Install parsers
  ts.install({
    "lua",
    "vim",
    "vimdoc",
    "query",
    "markdown",
    "markdown_inline",
    "ruby",
    "python",
    "javascript",
    "typescript",
    "tsx",
    "json",
    "yaml",
    "dockerfile",
    "html",
    "css",
    "bash",
    "nix",
  })

  -- Configure textobjects (now a separate setup call)
  local ok, textobjects = pcall(require, "nvim-treesitter-textobjects")
  if ok then
    textobjects.setup({
      select = {
        enable = true,
        lookahead = true,
      },
    })
  end
end

return M
