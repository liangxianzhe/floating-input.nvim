local M = {}

function M.window_center(input_width)
	return {
		relative = "editor",
		row = vim.o.lines / 2 - 1,
		col = vim.o.columns / 2 - input_width / 2,
	}
end

function M.under_cursor(_)
	return {
		relative = "cursor",
		row = 1,
		col = 0,
	}
end

function M.input(opts, on_confirm, win_config)
	local prompt = opts.prompt or "Input: "
	local default = opts.default or ""
	on_confirm = on_confirm or function() end

	-- Calculate a minimal width with a bit buffer
	local default_width = vim.str_utfindex(default) + 10
	local prompt_width = vim.str_utfindex(prompt) + 10
	local input_width = default_width > prompt_width and default_width or prompt_width

	local default_win_config = {
		focusable = true,
		style = "minimal",
		border = "rounded",
		width = input_width,
		height = 1,
		title = prompt,
	}

	-- Place the window near cursor or at the center of the window.
	local position_under_cursor = prompt == "New Name: "
	if position_under_cursor then
		default_win_config = vim.tbl_deep_extend("force", default_win_config, M.under_cursor(input_width))
	else
		default_win_config = vim.tbl_deep_extend("force", default_win_config, M.window_center(input_width))
	end

	-- Apply user's window config.
	win_config = vim.tbl_deep_extend("force", default_win_config, win_config)

	-- Create floating window.
	local buffer = vim.api.nvim_create_buf(false, true)
	local window = vim.api.nvim_open_win(buffer, true, win_config)
	vim.api.nvim_set_option_value("wrap", false, { win = window }) -- enable horizontal scrolling when exceeding window width
	vim.api.nvim_buf_set_text(buffer, 0, 0, 0, 0, { default })

	-- Put cursor at the end of the default value
	vim.cmd("startinsert")
	vim.api.nvim_win_set_cursor(window, { 1, vim.str_utfindex(default) + 1 })

	-- Enter to confirm
	vim.keymap.set({ "n", "i", "v" }, "<cr>", function()
		local lines = vim.api.nvim_buf_get_lines(buffer, 0, 1, false)
		vim.cmd("stopinsert")
		vim.api.nvim_win_close(window, true)
		on_confirm(lines[1])
	end, { buffer = buffer })

	-- Esc or q to close
	vim.keymap.set("n", "<esc>", function()
		vim.cmd("stopinsert")
		vim.api.nvim_win_close(window, true)
		on_confirm(nil)
	end, { buffer = buffer })
	vim.keymap.set("n", "q", function()
		vim.cmd("stopinsert")
		vim.api.nvim_win_close(window, true)
		on_confirm(nil)
	end, { buffer = buffer })

	-- With wrap=false the cursor is kept at the end of the line and the line is scrolled to the right when we type beyond the window width.
	-- Since InsertCharPre gets processed before the character is inserted and we're expanding the window width there,
	-- the net effect is that the window grows before the new character is inserted, so no scrolling actually happens.
	vim.api.nvim_create_autocmd("InsertCharPre", {
		buffer = buffer,
		callback = function()
			local new_char_len = vim.fn.strdisplaywidth(vim.v.char)
			local new_text_len = vim.api.nvim_win_get_cursor(0)[2] + new_char_len
			if new_text_len >= win_config.width then
				local new_width = new_text_len + 1 -- apparently in insert mode a 1 char padding is displayed past the cursor

				if position_under_cursor then
					vim.api.nvim_win_set_width(0, new_width)
				else
					-- Here we modify the previously created win_config variable, but that's ok since it's not used anymore.
					-- It's also local, so it will be recreated again next time a new input is opened.
					-- The advantage of reusing it is that we can set both width and col with 1 api call.
					win_config.width = new_width
					win_config.col = win_config.col - (new_width % 2) -- keep it centered
					vim.api.nvim_win_set_config(0, win_config)
				end
			end
		end,
	})
end

-- Deprecated. No need to call setup, will be removed soon.
function M.setup() end

return M
