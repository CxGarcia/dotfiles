-- Essential editor plugins
return {
    -- Surround plugin for operations like cs"' to change " to '
    {
        "kylechui/nvim-surround",
        version = "*",
        event = "VeryLazy",
        config = function()
            require("nvim-surround").setup({
                move_cursor = false,
                keymaps = {
                    visual = "gs",
                    visual_line = "gS"
                }
            })
        end
    },

    -- Comment plugin
    {
        "numToStr/Comment.nvim",
        event = "VeryLazy",
        config = function()
            require("Comment").setup()
        end
    },

    -- Auto pairs
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = function()
            require("nvim-autopairs").setup({
                check_ts = true,
                fast_wrap = {}
            })
        end
    },

    -- Marks in the gutter
    {
        "chentoast/marks.nvim",
        event = "VeryLazy",
        config = function()
            require("marks").setup({
                default_mappings = true,
                builtin_marks = { ".", "<", ">", "^" },
                cyclic = true,
                force_write_shada = false,
                refresh_interval = 250,
                sign_priority = { lower = 10, upper = 15, builtin = 8, bookmark = 20 },
                excluded_filetypes = {},
                bookmark_0 = {
                    sign = "⚑",
                    virt_text = "bookmark",
                    annotate = false
                },
                mappings = {}
            })
        end
    },

    -- Enhanced f/t motions
    {
        "ggandor/leap.nvim",
        event = "VeryLazy",
        config = function()
            require("leap").add_default_mappings()
        end
    },

    -- Enhanced text objects
    {
        "wellle/targets.vim",
        event = "VeryLazy"
    },

    -- Indent text objects (vai, vii)
    {
        "michaeljsmith/vim-indent-object",
        event = "VeryLazy"
    },

    -- Which-key - shows available keybindings
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        config = function()
            local wk = require("which-key")
            wk.setup({
                plugins = {
                    spelling = { enabled = true }
                }
            })
            wk.add({
                { "<leader>f", group = "Find" },
                { "<leader>b", group = "Buffer" },
                { "<leader>g", group = "Git/Go" },
                { "<leader>c", group = "Code" },
                { "<leader>r", group = "Rename" },
                { "<leader>x", group = "Diagnostics" }
            })
        end
    },

    -- Indent guides
    {
        "lukas-reineke/indent-blankline.nvim",
        event = { "BufReadPost", "BufNewFile" },
        main = "ibl",
        config = function()
            require("ibl").setup({
                indent = { char = "│" },
                scope = { enabled = false }
            })
        end
    },

    -- Git signs
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            require("gitsigns").setup({
                signs = {
                    add = { text = "│" },
                    change = { text = "│" },
                    delete = { text = "_" },
                    topdelete = { text = "‾" },
                    changedelete = { text = "~" }
                },
                on_attach = function(bufnr)
                    local gs = package.loaded.gitsigns
                    local keymap = vim.keymap.set

                    -- Navigate hunks
                    keymap("n", "]g", gs.next_hunk, { buffer = bufnr, desc = "Next git change" })
                    keymap("n", "[g", gs.prev_hunk, { buffer = bufnr, desc = "Previous git change" })
                    keymap("n", "]h", gs.next_hunk, { buffer = bufnr, desc = "Next hunk" })
                    keymap("n", "[h", gs.prev_hunk, { buffer = bufnr, desc = "Previous hunk" })
                    
                    -- Hunk actions
                    keymap("n", "<leader>gp", gs.preview_hunk, { buffer = bufnr, desc = "Preview hunk" })
                    keymap("n", "<leader>gb", gs.blame_line, { buffer = bufnr, desc = "Blame line" })
                    keymap("n", "<leader>gr", gs.reset_hunk, { buffer = bufnr, desc = "Reset hunk" })
                    keymap("n", "<leader>gs", gs.stage_hunk, { buffer = bufnr, desc = "Stage hunk" })
                    keymap("v", "<leader>gs", function() gs.stage_hunk({vim.fn.line('.'), vim.fn.line('v')}) end, 
                        { buffer = bufnr, desc = "Stage selected hunk" })
                end
            })
        end
    },

    -- Better UI components
    {
        "stevearc/dressing.nvim",
        event = "VeryLazy",
        config = true
    }
}

