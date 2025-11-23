-- LSP Configuration
return {
	-- Mason - LSP server installer (must be set up first)
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		build = ":MasonUpdate",
		config = function()
			require("mason").setup({
				ui = {
					border = "rounded",
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			})
		end,
	},

	-- Mason-lspconfig bridge (must be after mason)
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"gopls", -- Go
					"ts_ls", -- TypeScript/JavaScript
					"eslint", -- ESLint
					"lua_ls", -- Lua
				},
				automatic_installation = true,
			})
		end,
	},

	-- Neovim Lua API type definitions (must be before lspconfig)
	{
		"folke/neodev.nvim",
		opts = {},
	},

	-- LSP Configuration using new vim.lsp.config API (Neovim 0.11+)
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"folke/neodev.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			-- LSP capabilities with nvim-cmp support
			local capabilities = vim.lsp.protocol.make_client_capabilities()

			-- Merge with cmp capabilities if available
			local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
			if has_cmp then
				capabilities = vim.tbl_deep_extend("force", capabilities, cmp_nvim_lsp.default_capabilities())
			end

			-- Enable folding for nvim-ufo
			capabilities.textDocument.foldingRange = {
				dynamicRegistration = false,
				lineFoldingOnly = true,
			}

			-- LSP keymaps on attach
			local on_attach = function(client, bufnr)
				local opts = { buffer = bufnr, silent = true }
				local keymap = vim.keymap.set

				-- Jump to definition/declaration with priority: LSP > tag > search
				keymap("n", "gD", function()
					vim.lsp.buf.declaration()
				end, vim.tbl_extend("force", opts, { desc = "Go to declaration" }))

				keymap("n", "gd", function()
					vim.lsp.buf.definition()
				end, vim.tbl_extend("force", opts, { desc = "Go to definition" }))

				keymap("n", "gy", function()
					vim.lsp.buf.type_definition()
				end, vim.tbl_extend("force", opts, { desc = "Go to type definition" }))

				-- Hover with documentation + diagnostics
				local function hover_with_diagnostics()
					-- Show diagnostics first
					local _, winid = vim.diagnostic.open_float(nil, {
						scope = "cursor",
						focus = false,
						border = "rounded",
						source = "always",
						prefix = function(diagnostic, i, total)
							local icons = {
								[vim.diagnostic.severity.ERROR] = " ",
								[vim.diagnostic.severity.WARN] = " ",
								[vim.diagnostic.severity.INFO] = " ",
								[vim.diagnostic.severity.HINT] = " ",
							}
							return icons[diagnostic.severity] or "● ",
								"DiagnosticSign"
									.. vim.diagnostic.severity[diagnostic.severity]:sub(1, 1)
									.. vim.diagnostic.severity[diagnostic.severity]:sub(2):lower()
						end,
					})

					-- Then show hover documentation
					if not winid then
						vim.lsp.buf.hover()
					end
				end

				keymap(
					"n",
					"K",
					hover_with_diagnostics,
					vim.tbl_extend("force", opts, { desc = "Hover with diagnostics" })
				)
				keymap(
					"n",
					"gh",
					hover_with_diagnostics,
					vim.tbl_extend("force", opts, { desc = "Hover with diagnostics" })
				)
				keymap(
					"n",
					"gi",
					vim.lsp.buf.implementation,
					vim.tbl_extend("force", opts, { desc = "Go to implementation" })
				)
				keymap(
					"n",
					"gI",
					vim.lsp.buf.implementation,
					vim.tbl_extend("force", opts, { desc = "Go to implementation" })
				)
				keymap(
					"n",
					"<leader>k",
					vim.lsp.buf.signature_help,
					vim.tbl_extend("force", opts, { desc = "Signature help" })
				)
				keymap("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "Go to references" }))
				keymap("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
				-- cd for "change definition" - uses inc-rename for live preview
				keymap("n", "cd", function()
					return ":IncRename " .. vim.fn.expand("<cword>")
				end, vim.tbl_extend("force", opts, { expr = true, desc = "Change definition (rename)" }))
				keymap("n", "g.", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
				keymap("v", "g.", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
				keymap("n", "<leader>dl", function()
					vim.diagnostic.open_float({ focus = true })
				end, vim.tbl_extend("force", opts, { desc = "Line diagnostics" }))
				keymap(
					"n",
					"g[",
					vim.diagnostic.goto_prev,
					vim.tbl_extend("force", opts, { desc = "Previous diagnostic" })
				)
				keymap("n", "g]", vim.diagnostic.goto_next, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))
				keymap(
					"n",
					"<leader>q",
					vim.diagnostic.setloclist,
					vim.tbl_extend("force", opts, { desc = "Quickfix diagnostics" })
				)

				-- Notify when LSP attaches
				vim.notify("LSP attached: " .. client.name, vim.log.levels.INFO)
			end

			-- Configure diagnostic display
			vim.diagnostic.config({
				virtual_text = false, -- Disable inline diagnostics
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = " ",
						[vim.diagnostic.severity.WARN] = " ",
						[vim.diagnostic.severity.HINT] = " ",
						[vim.diagnostic.severity.INFO] = " ",
					},
				},
				underline = true, -- Keep underline highlighting
				update_in_insert = false,
				severity_sort = true,
				float = {
					border = "rounded",
					source = "always",
					focusable = true, -- Allow entering float to copy text
					style = "minimal",
					header = "",
					prefix = "",
				},
			})

			-- LSP handlers with rounded borders
			vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
			vim.lsp.handlers["textDocument/signatureHelp"] =
				vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

			-- Configure LSP servers using new vim.lsp.config API

			-- Go (gopls) configuration
			vim.lsp.config.gopls = {
				cmd = { "gopls" },
				filetypes = { "go", "gomod", "gowork", "gotmpl" },
				root_markers = { "go.work", "go.mod", ".git" },
				capabilities = capabilities,
				on_attach = on_attach,
				settings = {
					gopls = {
						analyses = {
							unusedparams = true,
							shadow = true,
						},
						staticcheck = true,
						gofumpt = true,
						usePlaceholders = true,
						completeUnimported = true,
						hints = {
							assignVariableTypes = true,
							compositeLiteralFields = true,
							constantValues = true,
							functionTypeParameters = true,
							parameterNames = true,
							rangeVariableTypes = true,
						},
					},
				},
			}

			-- TypeScript/JavaScript (ts_ls) configuration
			vim.lsp.config.ts_ls = {
				cmd = { "typescript-language-server", "--stdio" },
				cmd_env = { NODE_OPTIONS = "--max-old-space-size=16384" },
				filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
				root_markers = { "bun.lockb", "package.json", "tsconfig.json", "jsconfig.json", ".git" },
				capabilities = capabilities,
				on_attach = function(client, bufnr)
					-- Disable ts_ls formatting in favor of ESLint/Prettier
					client.server_capabilities.documentFormattingProvider = false
					client.server_capabilities.documentRangeFormattingProvider = false
					on_attach(client, bufnr)
				end,
				settings = {
					typescript = {
						inlayHints = {
							includeInlayParameterNameHints = "all",
							includeInlayParameterNameHintsWhenArgumentMatchesName = false,
							includeInlayFunctionParameterTypeHints = true,
							includeInlayVariableTypeHints = true,
							includeInlayPropertyDeclarationTypeHints = true,
							includeInlayFunctionLikeReturnTypeHints = true,
							includeInlayEnumMemberValueHints = true,
						},
					},
					javascript = {
						inlayHints = {
							includeInlayParameterNameHints = "all",
							includeInlayParameterNameHintsWhenArgumentMatchesName = false,
							includeInlayFunctionParameterTypeHints = true,
							includeInlayVariableTypeHints = true,
							includeInlayPropertyDeclarationTypeHints = true,
							includeInlayFunctionLikeReturnTypeHints = true,
							includeInlayEnumMemberValueHints = true,
						},
					},
				},
			}

			-- ESLint configuration
			vim.lsp.config.eslint = {
				cmd = { "vscode-eslint-language-server", "--stdio" },
				filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
				root_markers = { ".eslintrc", ".eslintrc.js", ".eslintrc.json", "package.json" },
				capabilities = capabilities,
				on_attach = function(client, bufnr)
					on_attach(client, bufnr)
					-- Auto-fix on save (only if ESLint is actually attached)
					if client.name == "eslint" then
						vim.api.nvim_create_autocmd("BufWritePre", {
							buffer = bufnr,
							callback = function()
								-- Use pcall to safely execute the command
								local ok, _ = pcall(vim.cmd, "EslintFixAll")
								if not ok then
									-- Silently fail if command doesn't exist yet
									-- This can happen if ESLint hasn't fully initialized
								end
							end,
						})
					end
				end,
				settings = {
					workingDirectory = { mode = "auto" },
				},
			}

			-- Lua (lua_ls) configuration for Neovim development
			-- Note: neodev.nvim provides proper type definitions
			vim.lsp.config.lua_ls = {
				cmd = { "lua-language-server" },
				filetypes = { "lua" },
				root_markers = { ".luarc.json", ".luacheckrc", ".stylua.toml", "stylua.toml", ".git" },
				capabilities = capabilities,
				on_attach = on_attach,
				settings = {
					Lua = {
						runtime = { version = "LuaJIT" },
						diagnostics = {
							-- Don't need to specify globals, neodev handles this
							globals = {},
						},
						workspace = {
							checkThirdParty = false,
							-- Don't set library manually, neodev.nvim handles this
						},
						telemetry = { enable = false },
						format = {
							enable = true,
							defaultConfig = {
								indent_style = "space",
								indent_size = "4",
							},
						},
						completion = {
							callSnippet = "Replace",
						},
					},
				},
			}

			-- Enable LSP servers for appropriate filetypes
			local function setup_go()
				vim.lsp.enable("gopls")
			end

			local function setup_typescript()
				vim.lsp.enable("ts_ls")
				vim.lsp.enable("eslint")
			end

			local function setup_lua()
				vim.lsp.enable("lua_ls")
			end

			-- Use FileType autocmds with proper filetype patterns
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "go", "gomod", "gowork", "gotmpl" },
				callback = setup_go,
			})

			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
				callback = setup_typescript,
			})

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "lua",
				callback = setup_lua,
			})
		end,
	},

	-- Additional Go tooling support
	{
		"ray-x/go.nvim",
		dependencies = {
			"ray-x/guihua.lua",
			"neovim/nvim-lspconfig",
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("go").setup({
				disable_defaults = false,
				go = "go",
				goimports = "gopls",
				fillstruct = "gopls",
				gofmt = "gofumpt",
				tag_transform = false,
				test_template = "",
				test_template_dir = "",
				comment_placeholder = "",
				lsp_cfg = false, -- We handle LSP configuration above
				lsp_gofumpt = true,
				lsp_on_attach = false,
				dap_debug = false,
				textobjects = false,
				lsp_inlay_hints = {
					enable = true,
					style = "inlay",
					only_current_line = false,
				},
			})

			-- Go-specific keymaps (buffer-local, only active in Go files)
			-- NOTE: Using <leader>go* prefix to avoid conflicts with git keybindings
			-- To debug keybindings: :KeymapShow <leader>goc
			-- To list all <leader>go keybindings: :KeymapList <leader>go
			-- To check for conflicts: :KeymapConflicts
			local function setup_go_keymaps()
				local keymap = vim.keymap.set
				local opts = { buffer = true, silent = true }
				keymap("n", "<leader>got", "<cmd>GoTest<CR>", vim.tbl_extend("force", opts, { desc = "Go Test" }))
				keymap(
					"n",
					"<leader>goT",
					"<cmd>GoTestFunc<CR>",
					vim.tbl_extend("force", opts, { desc = "Go Test Function" })
				)
				keymap(
					"n",
					"<leader>goc",
					"<cmd>GoCoverage<CR>",
					vim.tbl_extend("force", opts, { desc = "Go Coverage" })
				)
				keymap("n", "<leader>goi", "<cmd>GoImport<CR>", vim.tbl_extend("force", opts, { desc = "Go Import" }))
				keymap(
					"n",
					"<leader>gof",
					"<cmd>GoFillStruct<CR>",
					vim.tbl_extend("force", opts, { desc = "Go Fill Struct" })
				)
				keymap("n", "<leader>goe", "<cmd>GoIfErr<CR>", vim.tbl_extend("force", opts, { desc = "Go If Err" }))
			end

			-- Set up keymaps for Go files
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "go", "gomod" },
				callback = setup_go_keymaps,
			})
		end,
		event = { "CmdlineEnter" },
		ft = { "go", "gomod" },
		build = ':lua require("go.install").update_all_sync()',
	},

	-- Trouble.nvim - Project-wide diagnostics viewer
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		cmd = "Trouble",
		keys = {
			{
				"<leader>d",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "Diagnostics (Trouble)",
			},
			{
				"<leader>xX",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "Buffer Diagnostics (Trouble)",
			},
			{
				"<leader>xs",
				"<cmd>Trouble symbols toggle focus=false<cr>",
				desc = "Symbols (Trouble)",
			},
			{
				"<leader>xl",
				"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
				desc = "LSP Definitions / references / ... (Trouble)",
			},
			{
				"<leader>xL",
				"<cmd>Trouble loclist toggle<cr>",
				desc = "Location List (Trouble)",
			},
			{
				"<leader>xQ",
				"<cmd>Trouble qflist toggle<cr>",
				desc = "Quickfix List (Trouble)",
			},
		},
		config = function()
			require("trouble").setup({
				modes = {
					diagnostics = {
						auto_open = false,
						auto_close = false,
						auto_preview = true,
						auto_fold = false,
						focus = false,
					},
				},
			})
		end,
	},

	-- Conform.nvim for formatting
	{
		"stevearc/conform.nvim",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					go = { "goimports", "gofumpt" },
					javascript = { "prettier", "eslint_d" },
					typescript = { "prettier", "eslint_d" },
					javascriptreact = { "prettier", "eslint_d" },
					typescriptreact = { "prettier", "eslint_d" },
					json = { "prettier" },
					jsonc = { "prettier" },
					yaml = { "prettier" },
					markdown = { "prettier" },
					html = { "prettier" },
					css = { "prettier" },
					scss = { "prettier" },
					lua = { "stylua" },
				},
				format_on_save = {
					timeout_ms = 500,
					lsp_fallback = true,
				},
			})

			-- Format keymap with better error handling
			vim.keymap.set({ "n", "v" }, "<leader>fm", function()
				local conform = require("conform")
				conform.format({
					async = true,
					lsp_fallback = true,
					timeout_ms = 2000,
				}, function(err)
					if err then
						vim.notify("Format error: " .. tostring(err), vim.log.levels.ERROR)
					end
				end)
			end, { desc = "Format buffer" })
		end,
	},

	-- Mason-tool-installer for formatters
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					"goimports",
					"gofumpt",
					"prettier",
					"eslint_d",
					"stylua",
				},
				auto_update = true,
				run_on_start = true,
			})
		end,
	},

	-- Enhanced LSP rename with live preview
	{
		"smjonas/inc-rename.nvim",
		config = function()
			require("inc_rename").setup({
				input_buffer_type = "dressing",
			})
			vim.keymap.set("n", "<leader>rn", function()
				return ":IncRename " .. vim.fn.expand("<cword>")
			end, { expr = true, desc = "Rename symbol (with preview)" })
		end,
	},
}
