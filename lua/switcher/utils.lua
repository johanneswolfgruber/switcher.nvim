local M = {}

M.get_longest_string = function(strings)
  local longest = ''

  for _, str in ipairs(strings) do
    if #str > #longest then
      longest = str
    end
  end

  return longest
end

M.get_file_name = function(buf_name)
  return vim.fn.fnamemodify(buf_name, ':t')
end

M.advance_cursor_to_next_line = function(win, win_opts)
  local current_cursor_pos = vim.api.nvim_win_get_cursor(win)
  local new_line = (current_cursor_pos[1] + 1) % win_opts.height
  if new_line == 0 then
    new_line = win_opts.height
  end

  vim.api.nvim_win_set_cursor(win, { new_line, current_cursor_pos[2] })
end

return M
