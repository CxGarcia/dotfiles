-- Telescope - Fuzzy finder over lists
return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
			cond = function()
				return vim.fn.executable("make") == 1
			end,
		},
		{
			"nvim-telescope/telescope-frecency.nvim",
			dependencies = { "kkharji/sqlite.lua" },
		},
		{
			"fdschmidt93/telescope-egrepify.nvim",
		},
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")

		telescope.setup({
			defaults = {
				prompt_prefix = " ",
				selection_caret = " ",
				path_display = { "truncate" },
				-- Performance optimizations
				-- Note: ripgrep respects .gitignore by default via --glob flags
				file_ignore_patterns = {
					"%.git/",
					"%.DS_Store",
				},
				vimgrep_arguments = {
					"rg",
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
					"--hidden",
					"--glob=!.git/",
				},
				-- Use fzf for fuzzy finding
				file_sorter = require("telescope.sorters").get_fzf_sorter,
				generic_sorter = require("telescope.sorters").get_fzf_sorter,
				mappings = {
					i = {
						["<C-j>"] = actions.move_selection_next,
						["<C-k>"] = actions.move_selection_previous,
						["<C-q>"] = function(prompt_bufnr)
							actions.send_selected_to_qflist(prompt_bufnr)
							actions.open_qflist(prompt_bufnr)
						end,
						-- Send to Trouble for collapsible/foldable groups
						["<C-t>"] = function(prompt_bufnr)
							require("trouble.sources.telescope").open(prompt_bufnr)
						end,
						["<Esc>"] = actions.close,
					},
					n = {
						-- Also available in normal mode
						["<C-t>"] = function(prompt_bufnr)
							require("trouble.sources.telescope").open(prompt_bufnr)
						end,
					},
				},
			},
			pickers = {
				find_files = {
					hidden = true,
					-- Use fd for much faster file finding (install with: brew install fd)
					find_command = { "fd", "--type", "f", "--strip-cwd-prefix", "--hidden", "--exclude", ".git" },
				},
				lsp_references = {
					-- Show only filename:line:col in list, full preview on right
					fname_width = 50,
					show_line = false,
					include_declaration = false,
					include_current_line = false,
					path_display = { "smart" },
					layout_strategy = "vertical",
					layout_config = {
						width = 0.9,
						height = 0.9,
						preview_height = 0.6,
						mirror = false,
					},
				},
			},
			extensions = {
				project = {
					base_dirs = {
						vim.fn.expand("~/dev"),
					},
					sync_with_nvim_tree = true,
				},
				frecency = {
					show_scores = false,
					show_unindexed = true,
					ignore_patterns = { "*.git/*", "*/tmp/*", "*/node_modules/*" },
					workspaces = {
						["conf"] = vim.fn.expand("~/.config"),
						["dev"] = vim.fn.expand("~/dev"),
						["dotfiles"] = vim.fn.expand("~/dotfiles"),
					},
				},
				egrepify = {
					-- Enable file grouping (shows filename headers)
					title = true,
					filename_hl = "EgrepifyFile",
					lnum = true,
					lnum_hl = "EgrepifyLnum",
					col = false,
					results_ts_hl = true,
					-- AND mode: "foo bar" matches foo.*bar
					AND = true,
					permutations = false,
					-- Prefix filters for advanced searches
					prefixes = {
						-- Usage examples:
						-- #lua,md foo   - search only in .lua and .md files
						-- >conf foo     - search in paths containing "conf"
						-- &test foo     - search in filenames containing "test"
						-- !bar foo      - exclude lines containing "bar"
						["!"] = {
							flag = "invert-match",
						},
					},
				},
			},
		})

		-- Load extensions
		pcall(telescope.load_extension, "fzf")
		pcall(telescope.load_extension, "frecency")
		pcall(telescope.load_extension, "egrepify")

		-- Keymaps
		local keymap = vim.keymap.set

		-- File finding: use frecency for intelligent file discovery
		keymap("n", "<leader>p", "<cmd>Telescope frecency workspace=CWD<CR>", { desc = "Find files (smart)" })
		keymap("n", "<leader>P", "<cmd>Telescope frecency<CR>", { desc = "Find files (all workspaces)" })

		keymap("n", "<leader>d", "<cmd>Telescope diagnostics<CR>", { desc = "Project diagnostics" })

		-- Search: use egrepify for file-grouped results
		keymap("n", "<leader>fg", "<cmd>Telescope egrepify<CR>", { desc = "Live grep" })

		keymap("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "Find buffers" })
		keymap("n", "<leader>fH", "<cmd>Telescope help_tags<CR>", { desc = "Help tags" })
		keymap("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>", { desc = "Recent files" })
		keymap("n", "<leader>fc", "<cmd>Telescope grep_string<CR>", { desc = "Find string under cursor" })
		keymap("n", "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "Document symbols" })
		keymap("n", "<leader>fS", "<cmd>Telescope lsp_workspace_symbols<CR>", { desc = "Workspace symbols" })

		-- LSP references
		keymap("n", "ga", "<cmd>Telescope lsp_references<CR>", { desc = "LSP references" })
		keymap("n", "gA", "<cmd>Telescope lsp_references<CR>", { desc = "LSP references" })

		-- Git
		keymap("n", "<leader>gc", "<cmd>Telescope git_status<CR>", { desc = "Git changed files" })

		-- Terminals - custom picker to show only terminal buffers
		keymap("n", "<leader>tf", function()
			require("telescope.builtin").buffers({
				prompt_title = "Find Terminals",
				only_cwd = false,
				attach_mappings = function(_, map)
					-- Keep default mappings
					return true
				end,
				-- Filter to show only terminal buffers
				entry_maker = function(entry)
					local bufnr = entry.bufnr
					if vim.api.nvim_buf_get_option(bufnr, "buftype") == "terminal" then
						return require("telescope.make_entry").gen_from_buffer()(entry)
					end
				end,
			})
		end, { desc = "Find terminals" })
	end,
}
