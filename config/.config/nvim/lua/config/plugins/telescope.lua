-- Telescope - Fuzzy finder over lists
return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	keys = {
		-- File finding: use smart-open for intelligent file discovery with better path matching
		{
			"<leader>p",
			function()
				require("telescope").extensions.smart_open.smart_open({
					cwd_only = true, -- Scope to current working directory
					filename_first = true,
				})
			end,
			desc = "Find files (smart)",
		},

		-- Global smart-open across all known locations
		{
			"<leader>P",
			function()
				require("telescope").extensions.smart_open.smart_open({
					cwd_only = false, -- Search everywhere
					filename_first = true,
				})
			end,
			desc = "Find files (global smart)",
		},

		{ "<leader>d", "<cmd>Telescope diagnostics<CR>", desc = "Project diagnostics" },

		-- Search: use egrepify for file-grouped results
		{ "<leader>fg", "<cmd>Telescope egrepify<CR>", desc = "Live grep" },

		{ "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Find buffers" },
		{ "<leader>fH", "<cmd>Telescope help_tags<CR>", desc = "Help tags" },
		{ "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent files" },
		{ "<leader>fc", "<cmd>Telescope grep_string<CR>", desc = "Find string under cursor" },
		{ "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", desc = "Document symbols" },
		{ "<leader>fS", "<cmd>Telescope lsp_workspace_symbols<CR>", desc = "Workspace symbols" },

		-- LSP references
		{ "ga", "<cmd>Telescope lsp_references<CR>", desc = "LSP references" },
		{ "gA", "<cmd>Telescope lsp_references<CR>", desc = "LSP references" },

		-- Git
		{ "<leader>gc", "<cmd>Telescope git_status<CR>", desc = "Git changed files" },

		-- Terminals - custom picker to show only terminal buffers
		{
			"<leader>tf",
			function()
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
			end,
			desc = "Find terminals",
		},
	},
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
			"danielfalk/smart-open.nvim",
			branch = "0.2.x",
			dependencies = {
				"kkharji/sqlite.lua",
				{ "nvim-telescope/telescope-fzf-native.nvim" },
			},
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
					path_display = { "smart" }, -- Smart path display for better UX
				},
				buffers = {
					path_display = { "smart" },
					sort_mru = true,
					ignore_current_buffer = false,
				},
				oldfiles = {
					path_display = { "smart" },
					only_cwd = false,
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
				fzf = {
					fuzzy = true, -- false will only do exact matching
					override_generic_sorter = true, -- override the generic sorter
					override_file_sorter = true, -- override the file sorter
					case_mode = "smart_case", -- or "ignore_case" or "respect_case"
				},
				smart_open = {
					cwd_only = false, -- Allow searching outside CWD but prioritize it
					filename_first = true, -- Show filename before directory path
					match_algorithm = "fzf", -- Use fzf for optimal path matching
					show_hidden = true, -- Show hidden files (consistent with find_files config)
					ignore_patterns = {
						"*.git/*",
						"*/tmp/*",
						"*/node_modules/*",
						"*.DS_Store",
					},
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
					default_workspace = "CWD", -- Default to current directory
					auto_validate = false, -- Don't auto-validate DB for performance
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

		-- Load extensions in optimal order
		-- 1. fzf first (provides sorting for others)
		pcall(telescope.load_extension, "fzf")

		-- 2. smart-open (primary file finder)
		pcall(telescope.load_extension, "smart_open")

		-- 3. frecency (secondary, workspace-aware finder)
		pcall(telescope.load_extension, "frecency")

		-- 4. Other extensions
		pcall(telescope.load_extension, "egrepify")
	end,
}
