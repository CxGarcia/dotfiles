-- Completion configuration: nvim-cmp + Copilot + LuaSnip integration
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
			local copilot = require("copilot.suggestion")

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					-- Tab: Copilot → cmp menu → snippet → fallback
					["<Tab>"] = cmp.mapping(function(fallback)
						-- Priority 1: Accept Copilot ghost text if visible (and cmp menu not open)
						if copilot.is_visible() and not cmp.visible() then
							copilot.accept()
						-- Priority 2: Navigate cmp menu when open
						elseif cmp.visible() then
							cmp.select_next_item()
						-- Priority 3: Jump through snippet placeholders
						elseif luasnip.locally_jumpable(1) then
							luasnip.jump(1)
						-- Fallback: Regular tab behavior
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

					-- Ctrl+Space: Manually trigger completion
					["<C-Space>"] = cmp.mapping.complete(),

					-- Enter: Confirm selection
					["<CR>"] = cmp.mapping.confirm({ select = false }),

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
