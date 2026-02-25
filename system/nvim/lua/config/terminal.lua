local M = {}

function M.setup()
  require("toggleterm").setup({
    open_mapping = [[<c-\>]],
    direction = "float",
    float_opts = {
      border = "rounded",
    },
  })
end

return M

