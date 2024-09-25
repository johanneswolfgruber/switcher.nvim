local M = {}

local function get_buf_names()
	local buffers = vim.api.nvim_list_bufs()
	local buf_names = {}

	for _, buf in ipairs(buffers) do
		if vim.api.nvim_buf_is_loaded(buf) then
			local buf_name = vim.api.nvim_buf_get_name(buf)
			if buf_name ~= "" then
				-- Extract just the file name (without path)
				local file_name = vim.fn.fnamemodify(buf_name, ":t")
				table.insert(buf_names, buf, file_name)
			end
		end
	end

	local buf_content = {}
	for key, value in pairs(buf_names) do
		-- table.insert(buf_content, key .. ": " .. value)
		table.insert(buf_content, value)
	end

	return buf_content
end

local function get_scratch_buf(content)
	-- Create a new, scratch buffer (not listed in the buffer list)
	local buf = vim.api.nvim_create_buf(false, true)

	-- Set the content of the buffer (list of strings)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })

	return buf
end

local function get_win_opts(linenumbers)
	-- Define the size and position of the floating window
	local width = 80
	local height = linenumbers
	local win_width = vim.api.nvim_get_option_value("columns", {})
	local win_height = vim.api.nvim_get_option_value("lines", {})

	return {
		title = " Buffer Switcher ",
		title_pos = "center",
		style = "minimal",
		relative = "editor",
		width = width,
		height = height,
		row = (win_height - height) / 2, -- Center the window vertically
		col = (win_width - width) / 2, -- Center the window horizontally
		border = "rounded", -- Optional: Set border style (rounded, single, etc.)
	}
end

M.open_switcher_window = function(timeout)
	local content = get_buf_names()

	-- Create the floating window
	local buf = get_scratch_buf(content)
	print(#content)
	local win_opts = get_win_opts(#content)
	local win = vim.api.nvim_open_win(buf, true, win_opts)

	local function close_window()
		-- Get the current line under the cursor
		local cursor_pos = vim.api.nvim_win_get_cursor(win)
		local selected_buf_name = vim.api.nvim_buf_get_lines(buf, cursor_pos[1] - 1, cursor_pos[1], false)[1]

		-- Close the floating window
		vim.api.nvim_win_close(win, true)

		local buffers = vim.api.nvim_list_bufs()
		-- Find the buffer that corresponds to the selected file name
		for _, b in ipairs(buffers) do
			local full_buf_name = vim.api.nvim_buf_get_name(b)
			local file_name = vim.fn.fnamemodify(full_buf_name, ":t")
			if file_name == selected_buf_name then
				-- Open the buffer in the current window
				vim.api.nvim_set_current_buf(b)
				return
			end
		end
	end

	local timer = vim.uv.new_timer()
	timer:start(timeout, 0, vim.schedule_wrap(close_window))

	local function reset_inactivity_timer()
		local current_cursor_pos = vim.api.nvim_win_get_cursor(win)
		print("Current cursor pos: " .. current_cursor_pos[1] .. ", " .. current_cursor_pos[2])
		local new_line
		if current_cursor_pos[1] + 1 > win_opts.height then
			new_line = 1
		else
			new_line = current_cursor_pos[1] + 1
		end

		vim.api.nvim_win_set_cursor(win, { new_line, current_cursor_pos[2] })

		if timer then
			timer:stop()
			timer:close()
		end

		timer = vim.uv.new_timer()
		timer:start(timeout, 0, vim.schedule_wrap(close_window))
	end

	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"<C-^>",
		"",
		{ noremap = true, silent = true, callback = reset_inactivity_timer }
	)
end

return M
