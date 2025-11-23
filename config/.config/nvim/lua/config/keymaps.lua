-- Keymaps
local keymap = vim.keymap.set

-- Note: Tmux navigation keymaps (C-h/j/k/l) are configured in tmux-integration.lua plugin
-- This ensures they're only set up after the plugin is loaded

-- Resize windows
keymap("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase window height" })
keymap("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease window height" })
keymap("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
keymap("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

-- Better indenting
keymap("v", "<", "<gv", { desc = "Indent left" })
keymap("v", ">", ">gv", { desc = "Indent right" })

-- Move text up and down
keymap("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
keymap("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- Keep cursor centered when scrolling
keymap("n", "<C-d>", "<C-d>zz", { desc = "Scroll down" })
keymap("n", "<C-u>", "<C-u>zz", { desc = "Scroll up" })
keymap("n", "n", "nzzzv", { desc = "Next search result" })
keymap("n", "N", "Nzzzv", { desc = "Previous search result" })

-- Clear search highlight with Esc
keymap("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Better paste (don't yank replaced text)
keymap("x", "p", '"_dP', { desc = "Paste without yanking" })

-- Delete and copy in visual mode
keymap("x", "x", "d", { desc = "Cut (delete and copy)" })

-- Quick save and quit
keymap("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
keymap("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })

-- Buffer navigation
keymap("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
keymap("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })

-- Smart buffer deletion - switch to next normal buffer before deleting
local function smart_delete_buffer()
	local current_buf = vim.api.nvim_get_current_buf()
	local buffers = vim.api.nvim_list_bufs()

	-- Find the next normal buffer (not NvimTree, terminal, etc.)
	local normal_buffers = {}
	for _, buf in ipairs(buffers) do
		if vim.api.nvim_buf_is_loaded(buf) and buf ~= current_buf then
			local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
			local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
			-- Skip special buffers
			if buftype == "" and filetype ~= "NvimTree" then
				table.insert(normal_buffers, buf)
			end
		end
	end

	-- If we have other normal buffers, switch to one before deleting
	if #normal_buffers > 0 then
		vim.api.nvim_set_current_buf(normal_buffers[1])
	end

	-- Delete the original buffer
	vim.api.nvim_buf_delete(current_buf, { force = false })
end

keymap("n", "<leader>bd", smart_delete_buffer, { desc = "Delete buffer" })

-- Search across all files
keymap("n", "g/", "<cmd>Telescope egrepify<CR>", { desc = "Search across all files" })
keymap("n", "<leader>k", "<cmd>Telescope project<CR>", { desc = "Search projects" })

-- Commands to copy file paths
vim.api.nvim_create_user_command("Crp", function()
	local path = vim.fn.fnamemodify(vim.fn.expand("%"), ":.")
	if path == "" then
		vim.notify("No file in current buffer", vim.log.levels.WARN)
		return
	end
	vim.fn.setreg("+", path)
	vim.notify("Copied relative path: " .. path, vim.log.levels.INFO)
end, { desc = "Copy relative path of current buffer" })

vim.api.nvim_create_user_command("Cap", function()
	local path = vim.fn.expand("%:p")
	if path == "" then
		vim.notify("No file in current buffer", vim.log.levels.WARN)
		return
	end
	vim.fn.setreg("+", path)
	vim.notify("Copied absolute path: " .. path, vim.log.levels.INFO)
end, { desc = "Copy absolute path of current buffer" })
