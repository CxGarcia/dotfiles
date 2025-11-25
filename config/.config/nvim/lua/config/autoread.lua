-- Automatic file change detection for external modifications (AI tools, git, etc.)
-- This module ensures buffers stay in sync with disk when files are modified externally

local M = {}

-- Helper function to refresh LSP diagnostics and semantic tokens after file reload
local function refresh_lsp_after_reload(bufnr)
	local clients = vim.lsp.get_clients({ bufnr = bufnr })

	if #clients == 0 then
		return
	end

	-- Small delay to ensure buffer is fully reloaded before notifying LSP
	vim.defer_fn(function()
		-- Trigger diagnostic refresh for all attached LSP clients
		for _, client in ipairs(clients) do
			if client.supports_method("textDocument/diagnostic") then
				vim.lsp.buf.document_highlight()
			end
		end

		-- Request fresh diagnostics
		vim.diagnostic.reset(nil, bufnr)

		-- Trigger a small text change to force LSP to re-analyze
		-- This ensures semantic tokens and other features stay accurate
		local line_count = vim.api.nvim_buf_line_count(bufnr)
		if line_count > 0 then
			vim.api.nvim_buf_call(bufnr, function()
				-- Force LSP update by triggering didChange
				vim.api.nvim_exec_autocmds("TextChanged", { buffer = bufnr })
			end)
		end
	end, 100)
end

-- Helper function to open diff view for conflicting changes
local function show_diff_for_conflict(bufnr)
	local filepath = vim.api.nvim_buf_get_name(bufnr)
	local filename = vim.fn.fnamemodify(filepath, ":t")

	-- Create a scratch buffer with the disk version
	local disk_buf = vim.api.nvim_create_buf(false, true)
	local disk_lines = vim.fn.readfile(filepath)
	vim.api.nvim_buf_set_lines(disk_buf, 0, -1, false, disk_lines)
	vim.api.nvim_buf_set_option(disk_buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(disk_buf, "bufhidden", "wipe")

	-- Open vertical split with diff
	vim.cmd("vsplit")
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, disk_buf)

	-- Enable diff mode in both windows
	vim.cmd("diffthis")
	vim.cmd("wincmd p") -- Go back to original window
	vim.cmd("diffthis")

	-- Notify user about the conflict
	vim.notify(
		string.format(
			"File conflict detected: %s\n\nLeft: Your unsaved changes\nRight: Disk version\n\nResolve manually then :diffoff and choose which to save",
			filename
		),
		vim.log.levels.ERROR,
		{ title = "File Conflict - Manual Merge Required" }
	)
end

-- Create autocmd group for all autoread functionality
local autoread_group = vim.api.nvim_create_augroup("AutoRead", { clear = true })

-- Trigger checktime on various events to detect external file changes
vim.api.nvim_create_autocmd({
	"FocusGained", -- When Neovim window gains focus (switching from terminal/other apps)
	"BufEnter", -- When entering a buffer
	"CursorHold", -- After cursor is idle (uses 'updatetime' setting: 250ms)
	"CursorHoldI", -- After cursor is idle in insert mode
}, {
	group = autoread_group,
	pattern = "*",
	callback = function()
		-- Only run checktime if not in command-line mode or command-line window
		-- This prevents errors when the autocmd fires during command editing
		local mode = vim.api.nvim_get_mode().mode
		if mode ~= "c" and vim.fn.getcmdwintype() == "" then
			vim.cmd("checktime")
		end
	end,
	desc = "Check for external file changes",
})

-- Notify when a file has been reloaded due to external changes
vim.api.nvim_create_autocmd("FileChangedShellPost", {
	group = autoread_group,
	pattern = "*",
	callback = function()
		local bufnr = vim.api.nvim_get_current_buf()
		local filename = vim.fn.expand("%:t")

		-- Show notification about successful reload
		vim.notify(
			string.format("File changed on disk. Buffer reloaded: %s", filename),
			vim.log.levels.WARN,
			{ title = "External File Change" }
		)

		-- Refresh LSP to keep diagnostics and semantic tokens accurate
		refresh_lsp_after_reload(bufnr)
	end,
	desc = "Notification and LSP refresh after file reload",
})

-- Handle file changes when buffer has unsaved changes (conflict scenario)
vim.api.nvim_create_autocmd("FileChangedShell", {
	group = autoread_group,
	pattern = "*",
	callback = function()
		local bufnr = vim.api.nvim_get_current_buf()
		local filename = vim.fn.expand("%:t")

		-- Only handle if buffer is modified (has unsaved changes)
		if vim.bo[bufnr].modified then
			-- Open diff view to help user manually merge changes
			vim.schedule(function()
				show_diff_for_conflict(bufnr)
			end)

			-- Return v:fcs_choice = "" to prevent Neovim's default prompt
			-- We're handling this with our custom diff view
			vim.v.fcs_choice = ""
		end
	end,
	desc = "Handle file conflicts with diff view",
})

return M
