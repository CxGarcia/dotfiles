return {
	-- GitHub Copilot (native Lua implementation with ghost text)
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				-- Enable native suggestion module for inline ghost text
				suggestion = {
					enabled = true,
					auto_trigger = true,
					hide_during_completion = true, -- Hide ghost text when cmp menu opens (prevents visual conflicts)
					debounce = 75,
					keymap = {
						accept = false, -- We'll handle Tab manually
						accept_word = "<M-w>", -- Alt+w to accept word
						accept_line = "<M-l>", -- Alt+l to accept line
						next = "<M-]>", -- Alt+] for next suggestion
						prev = "<M-[>", -- Alt+[ for previous suggestion
						dismiss = "<C-e>", -- Ctrl+e to dismiss (changed from C-] to avoid tag jump conflict)
					},
				},
				panel = { enabled = false },

				-- Filetypes to disable Copilot in
				filetypes = {
					[".env"] = false, -- Environment files with secrets
					gitcommit = false, -- Git commits should be written by the user
					help = false, -- Help files are documentation
				},

				-- Node.js configuration
				copilot_node_command = vim.fn.exepath("node"),
			})
		end,
	},
}
