return {
	"greggh/claude-code.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim", -- Required for git operations
	},
	config = function()
		require("claude-code").setup({
			command = "claude --dangerously-skip-permissions",
			window = {
				position = "float",
				float = {
					width = "80%", -- Width: number of columns or percentage string
					height = "80%", -- Height: number of rows or percentage string
					row = "center", -- Row position: number, "center", or percentage string
					col = "center", -- Column position: number, "center", or percentage string
					relative = "editor", -- Relative to: "editor" or "cursor"
					border = "rounded", -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
				},
			},
		})
	end,
}
