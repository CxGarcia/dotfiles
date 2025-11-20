return {
    "rose-pine/neovim",
    name = "rose-pine",
    config = function()
        local bg = "#252c33"
        local bg_highlight = "#2d3843"

        require("rose-pine").setup({
            styles = {
                transparency = false,
            },
            highlight_groups = {
                -- Main backgrounds
                Normal = { bg = bg },
                NormalFloat = { bg = bg },
                NormalNC = { bg = bg },

                -- Statusline / Winbar
                StatusLine = { bg = bg },
                StatusLineNC = { bg = bg },
                StatusLineTerm = { bg = bg },
                StatusLineTermNC = { bg = bg },
                WinBar = { bg = bg },
                WinBarNC = { bg = bg },

                -- Tabline
                TabLine = { bg = bg },
                TabLineFill = { bg = bg },
                TabLineSel = { bg = bg_highlight },

                -- Floating windows
                FloatTitle = { bg = bg },
                Folded = { bg = bg },

                -- Completion menu
                Pmenu = { bg = bg },
                PmenuExtra = { bg = bg },
                PmenuKind = { bg = bg },
                PmenuSbar = { bg = bg },
                PmenuSel = { bg = bg_highlight },
                PmenuExtraSel = { bg = bg_highlight },
                PmenuKindSel = { bg = bg_highlight },

                -- Cursor and selection highlights
                CursorLine = { bg = bg_highlight },
                CursorColumn = { bg = bg_highlight },
                Visual = { bg = bg_highlight },

                -- LSP highlights
                LspReferenceRead = { bg = bg_highlight },
                LspReferenceText = { bg = bg_highlight },
                LspReferenceWrite = { bg = bg_highlight },

                -- Additional UI elements
                ColorColumn = { bg = bg },
            }
        })
        vim.cmd("colorscheme rose-pine")
    end
}
