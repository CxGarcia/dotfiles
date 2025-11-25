-- Completion configuration: nvim-cmp + Copilot + LuaSnip integration
--
-- ARCHITECTURE DECISION:
-- Tab key prioritizes Copilot ghost text when visible, then falls back to cmp menu navigation.
-- With hide_during_completion = true, only one system is visible at a time:
-- - Ghost text shows when no cmp menu (fast, immediate suggestions)
-- - cmp menu shows when triggered (LSP, snippets, etc.) and hides ghost text
-- This prevents visual conflicts while preserving Tab-to-accept Copilot muscle memory.
--
return {
	-- nvim-cmp: Completion plugin with LSP support
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp", -- LSP completion source
			"hrsh7th/cmp-buffer", -- Buffer completion source
			"hrsh7th/cmp-path", -- Path completion source
			"L3MON4D3/LuaSnip", -- Snippet engine
			"saadparwaiz1/cmp_luasnip", -- LuaSnip completion source
			"zbirenbaum/copilot.lua", -- EXPLICIT: Copilot dependency for Tab handler
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			local has_copilot, copilot = pcall(require, "copilot.suggestion")

			cmp.setup({
				-- Auto-select first completion item
				preselect = cmp.PreselectMode.Item,
				completion = {
					completeopt = "menu,menuone,noinsert",
				},
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					-- Tab: Copilot → cmp menu → snippet → fallback
					["<Tab>"] = cmp.mapping(function(fallback)
						if has_copilot and copilot.is_visible() then
							copilot.accept()
						elseif cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.locally_jumpable(1) then
							luasnip.jump(1)
						else
							fallback()
						end
					end, { "i", "s" }),

					-- Shift-Tab: Navigate backwards
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.locally_jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),

					-- Arrow keys: Navigate cmp menu
					["<Down>"] = cmp.mapping.select_next_item(),
					["<Up>"] = cmp.mapping.select_prev_item(),

					-- Ctrl+Space: Manually trigger completion
					["<C-Space>"] = cmp.mapping.complete(),

					-- Enter: Confirm selection (auto-selects first item if nothing selected)
					["<CR>"] = cmp.mapping.confirm({ select = true }),

					-- Ctrl+e: Close completion menu
					["<C-e>"] = cmp.mapping.abort(),

					-- Scroll docs
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
				}),
				sources = {
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "path" },
					{ name = "buffer", keyword_length = 3 },
				},
				formatting = {
					format = function(entry, vim_item)
						-- Add source name to completion items
						vim_item.menu = ({
							nvim_lsp = "[LSP]",
							luasnip = "[Snip]",
							buffer = "[Buf]",
							path = "[Path]",
						})[entry.source.name]
						return vim_item
					end,
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
			})
		end,
	},

	-- cmp-cmdline: Command and search mode completions
	{
		"hrsh7th/cmp-cmdline",
		event = "CmdlineEnter",
		dependencies = { "hrsh7th/nvim-cmp" },
		config = function()
			local cmp = require("cmp")

			-- Command mode completions (:)
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" },
					{ name = "cmdline" }
				})
			})

			-- Search mode completions (/ and ?)
			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" }
				}
			})
		end,
	},

	-- LuaSnip (snippet engine)
	{
		"L3MON4D3/LuaSnip",
		lazy = true,
		dependencies = {
			"rafamadriz/friendly-snippets", -- Collection of snippets
		},
		config = function()
			-- Load VSCode-style snippets
			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},
}
