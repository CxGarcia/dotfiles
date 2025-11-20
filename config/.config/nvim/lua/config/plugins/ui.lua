-- UI enhancements
return {
    -- Beautiful statusline
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            local bg_highlight = "#2d3843"

            -- Get rose-pine theme and override background colors
            local rose_pine = require("lualine.themes.rose-pine")

            -- Override the b and c section backgrounds to use our highlight color
            for _, mode in pairs(rose_pine) do
                if mode.b then mode.b.bg = bg_highlight end
                if mode.c then mode.c.bg = bg_highlight end
            end

            require("lualine").setup({
                options = {
                    theme = rose_pine,
                    component_separators = { left = "", right = "" },
                    section_separators = { left = "", right = "" },
                    globalstatus = true
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = { "branch", "diff", "diagnostics" },
                    lualine_c = { { "filename", path = 1 } },
                    lualine_x = { "encoding", "fileformat", "filetype" },
                    lualine_y = { "progress" },
                    lualine_z = { "location" }
                }
            })
        end
    },

    -- Buffer line
    {
        "akinsho/bufferline.nvim",
        event = "VeryLazy",
        version = "*",
        dependencies = "nvim-tree/nvim-web-devicons",
        config = function()
            require("bufferline").setup({
                options = {
                    mode = "buffers",
                    separator_style = "slant",
                    always_show_bufferline = false,
                    show_buffer_close_icons = false,
                    show_close_icon = false,
                    color_icons = true,
                    diagnostics = "nvim_lsp",
                    offsets = {
                        {
                            filetype = "NvimTree",
                            text = "File Explorer",
                            highlight = "Directory",
                            text_align = "left"
                        }
                    }
                }
            })
        end
    },

    -- File explorer
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("nvim-tree").setup({
                disable_netrw = true,
                hijack_netrw = true,
                view = {
                    width = 30,
                    side = "left"
                },
                renderer = {
                    group_empty = true,
                    highlight_git = true,
                    icons = {
                        show = {
                            git = true,
                            folder = true,
                            file = true,
                            folder_arrow = true
                        }
                    }
                },
                filters = {
                    dotfiles = false,
                    custom = { "^.git$" }
                }
            })

            -- Keymap
            vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
        end
    },

    -- IDE-like breadcrumbs
    {
        "Bekaboo/dropbar.nvim",
        event = "BufReadPost",
        config = function()
            require('dropbar').setup({
                icons = {
                    enable = true,
                },
                bar = {
                    sources = function(buf, _)
                        local sources = require('dropbar.sources')
                        local utils = require('dropbar.utils')
                        if vim.bo[buf].ft == 'markdown' then
                            return {
                                sources.path,
                                sources.markdown,
                            }
                        end
                        if vim.bo[buf].buftype == 'terminal' then
                            return {
                                sources.terminal,
                            }
                        end
                        return {
                            sources.path,
                            utils.source.fallback({
                                sources.lsp,
                                sources.treesitter,
                            }),
                        }
                    end,
                },
            })
        end
    }
}


