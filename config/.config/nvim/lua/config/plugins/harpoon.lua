return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	keys = {
		{
			"<leader>a",
			function()
				require("harpoon"):list():add()
				vim.notify("File harpooned!", vim.log.levels.INFO)
			end,
			desc = "Harpoon: Add file",
		},

		{ "<leader>fh", "<cmd>Telescope harpoon marks<cr>", desc = "Harpoon: View marks" },

		{
			"<leader>1",
			function()
				require("harpoon"):list():select(1)
			end,
			desc = "Harpoon: File 1",
		},

		{
			"<leader>2",
			function()
				require("harpoon"):list():select(2)
			end,
			desc = "Harpoon: File 2",
		},

		{
			"<leader>3",
			function()
				require("harpoon"):list():select(3)
			end,
			desc = "Harpoon: File 3",
		},

		{
			"<leader>4",
			function()
				require("harpoon"):list():select(4)
			end,
			desc = "Harpoon: File 4",
		},

		{
			"<leader>5",
			function()
				require("harpoon"):list():select(5)
			end,
			desc = "Harpoon: File 5",
		},

		{
			"<C-S-P>",
			function()
				require("harpoon"):list():prev()
			end,
			desc = "Harpoon: Previous",
		},

		{
			"<C-S-N>",
			function()
				require("harpoon"):list():next()
			end,
			desc = "Harpoon: Next",
		},
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
	},
	config = function()
		local harpoon = require("harpoon")
		harpoon:setup({})

		-- Load Telescope extension for Harpoon
		require("telescope").load_extension("harpoon")
	end,
}
