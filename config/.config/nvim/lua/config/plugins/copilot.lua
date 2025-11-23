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
					hide_during_completion = true,
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
					yaml = false,
					markdown = false,
					help = false,
					gitcommit = false,
					gitrebase = false,
					hgcommit = false,
					svn = false,
					cvs = false,
					["."] = false,
					-- SECURITY: Disable in files that commonly contain secrets
					[".env"] = false,
					env = false,
					json = false, -- May contain secrets in config files
					conf = false,
					config = false,
					-- Shell scripts may contain hardcoded credentials
					sh = false,
					bash = false,
					zsh = false,
				},

				-- Node.js configuration (use absolute path for security)
				copilot_node_command = vim.fn.exepath("node") ~= "" and vim.fn.exepath("node") or "node",

				-- Server options
				server_opts_overrides = {},
			})
		end,
	},
}
