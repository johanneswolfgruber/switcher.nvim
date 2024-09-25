local M = {}

local default_config = require("switcher.config")
local switcher = require("switcher.switcher")

M.setup = function(user_config)
	M.config = vim.tbl_extend("force", default_config, user_config or {})

	print(vim.inspect(M.config))

	vim.api.nvim_create_user_command("SwitcherOpen", function()
		switcher.open_switcher_window(M.config.timeout)
	end, {})

	vim.api.nvim_set_keymap("n", M.config.custom_keymap, ":SwitcherOpen<CR>", { noremap = true, silent = true })
end

return M
