local M = {}
local utils = require 'switcher.utils'
local bufs = require 'switcher.buffers'
local wins = require 'switcher.windows'

local function on_cursor_moved(buffers, win)
  local cursor_pos = vim.api.nvim_win_get_cursor(win)

  for i, buf in ipairs(buffers) do
    if i == cursor_pos[1] then
      buf.is_selected = true
    else
      buf.is_selected = false
    end
  end
end

M.open_switcher_window = function(config)
  local buffers = bufs.get_all_buffers()
  local content = bufs.get_scratch_buf_content(buffers)
  local scratch_buf = bufs.get_scratch_buf(content)
  local win_opts = wins.get_win_opts(#content, #utils.get_longest_string(content) + 10)
  local win = vim.api.nvim_open_win(scratch_buf, true, win_opts)
  vim.api.nvim_set_option_value('cursorline', true, { win = win })
  utils.advance_cursor_to_next_line(win, win_opts)

  local cursor_moved_group = vim.api.nvim_create_augroup('CursorMovedGroup', { clear = false })
  vim.api.nvim_create_autocmd('CursorMoved', {
    group = cursor_moved_group,
    callback = function()
      on_cursor_moved(buffers, win)
    end,
    buffer = scratch_buf,
  })

  local timer = vim.uv.new_timer()

  M.close_window = function()
    if timer then
      timer:stop()
      timer:close()
    end

    vim.api.nvim_win_close(win, true)

    for _, buf in ipairs(buffers) do
      if buf.is_selected then
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
