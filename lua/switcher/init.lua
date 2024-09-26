local M = {}

local default_config = require 'switcher.config'
local switcher = require 'switcher.switcher'

M.setup = function(user_config)
  M.config = vim.tbl_extend('force', default_config, user_config or {})

  vim.keymap.set('n', M.config.custom_keymap, function()
    switcher.open_switcher_window(M.config)
  end, { noremap = true, silent = true, desc = 'Open Switcher' })
end

return M
