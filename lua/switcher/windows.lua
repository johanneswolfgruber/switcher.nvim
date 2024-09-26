local M = {}

M.get_win_opts = function(height, width)
  local win_width = vim.api.nvim_get_option_value('columns', {})
  local win_height = vim.api.nvim_get_option_value('lines', {})

  return {
    title = ' Buffer Switcher ',
    title_pos = 'center',
    style = 'minimal',
    relative = 'editor',
    width = width,
    height = height,
    row = (win_height - height) / 2,
    col = (win_width - width) / 2,
    border = 'rounded',
  }
end

return M
