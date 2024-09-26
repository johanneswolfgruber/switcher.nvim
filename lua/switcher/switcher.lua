local M = {}
local utils = require 'switcher.utils'
local bufs = require 'switcher.buffers'
local wins = require 'switcher.windows'

M.open_switcher_window = function(config)
  local content = bufs.get_scratch_buf_content()
  local scratch_buf = bufs.get_scratch_buf(content)
  local win_opts = wins.get_win_opts(#content, #utils.get_longest_string(content) + 10)
  local win = vim.api.nvim_open_win(scratch_buf, true, win_opts)
  vim.api.nvim_set_option_value('cursorline', true, { win = win })
  utils.advance_cursor_to_next_line(win, win_opts)

  local timer = vim.uv.new_timer()

  M.close_window = function()
    local cursor_pos = vim.api.nvim_win_get_cursor(win)
    local selected_buf_name = vim.api.nvim_buf_get_lines(scratch_buf, cursor_pos[1] - 1, cursor_pos[1], false)[1]

    if timer then
      timer:stop()
      timer:close()
    end

    vim.api.nvim_win_close(win, true)

    local buffers = bufs.get_all_buffers()
    for _, buf in ipairs(buffers) do
      if string.find(selected_buf_name, buf.name) then
        vim.api.nvim_set_current_buf(buf.bufnr)
        return
      end
    end
  end

  timer:start(config.timeout, 0, vim.schedule_wrap(M.close_window))

  local function reset_inactivity_timer()
    utils.advance_cursor_to_next_line(win, win_opts)

    if timer then
      timer:stop()
      timer:close()
    end

    timer = vim.uv.new_timer()
    timer:start(config.timeout, 0, vim.schedule_wrap(M.close_window))
  end

  vim.keymap.set(
    'n',
    config.custom_keymap,
    reset_inactivity_timer,
    { noremap = true, silent = true, desc = 'Reset Switcher Inactivity Timer', buffer = scratch_buf }
  )
  vim.keymap.set('n', 'q', M.close_window, { noremap = true, silent = true, desc = 'Close Switcher', buffer = scratch_buf })
  vim.keymap.set('n', '<CR>', M.close_window, { noremap = true, silent = true, desc = 'Close Switcher', buffer = scratch_buf })
end

return M
