local M = {}
local utils = require 'switcher.utils'

local function highlight(bufnr, linenr, line_content, pattern, hl_group)
  local match_start, match_end = string.find(line_content, pattern)

  if match_start then
    local ns_id = vim.api.nvim_create_namespace(hl_group)
    vim.api.nvim_buf_set_extmark(bufnr, ns_id, linenr, match_start - 1, {
      end_col = match_end,
      hl_group = hl_group,
      priority = 100,
    })
  end
end

M.get_all_buffers = function()
  local buffers = {}

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.fn.buflisted(bufnr) == 1 then
      local name = utils.get_file_name(vim.api.nvim_buf_get_name(bufnr))
      local modified = vim.api.nvim_get_option_value('modified', { buf = bufnr })
      table.insert(buffers, {
        bufnr = bufnr,
        name = name,
        display_name = bufnr .. ': ' .. name .. (modified and ' ●' or ''),
        modified = modified,
        last_accessed = vim.fn.getbufinfo(bufnr)[1].lastused,
        is_selected = false,
      })
    end
  end

  table.sort(buffers, function(a, b)
    return a.last_accessed > b.last_accessed
  end)

  return buffers
end

M.get_scratch_buf_content = function(buffers)
  local lines = {}

  for _, buf in ipairs(buffers) do
    table.insert(lines, buf.display_name)
  end

  return lines
end

M.get_scratch_buf = function(content)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  for i, line in ipairs(content) do
    highlight(buf, i - 1, line, '(.*:)', 'Comment')
    highlight(buf, i - 1, line, '●', 'Keyword')
  end
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })

  return buf
end

return M
