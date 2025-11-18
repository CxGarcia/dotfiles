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
            end
        }
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
                file_ignore_patterns = {
                    "%.git/",
                    "node_modules/",
                    "%.cache/",
                    "%.venv/",
                    "__pycache__/",
                    "%.next/",
                    "dist/",
                    "build/",
                    "target/",
                    "%.pytest_cache/",
                    "%.idea/",
                    "%.vscode/",
                    "%.DS_Store",
                    "package%-lock%.json",
                    "yarn%.lock",
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
                mappings = {
                    i = {
                        ["<C-j>"] = actions.move_selection_next,
                        ["<C-k>"] = actions.move_selection_previous,
                        ["<C-q>"] = function(prompt_bufnr)
                            actions.send_selected_to_qflist(prompt_bufnr)
                            actions.open_qflist(prompt_bufnr)
                        end,
                        ["<Esc>"] = actions.close
                    }
                }
            },
            pickers = {
                find_files = {
                    hidden = true,
                    -- Use fd for much faster file finding (install with: brew install fd)
                    find_command = { "fd", "--type", "f", "--strip-cwd-prefix", "--hidden", "--exclude", ".git" }
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
                }
            }
        })

        -- Load fzf extension if available
        pcall(telescope.load_extension, "fzf")

        -- Keymaps
        local keymap = vim.keymap.set
        keymap("n", "<leader>p", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
        keymap("n", "<leader>d", "<cmd>Telescope diagnostics<CR>", { desc = "Project diagnostics" })
        keymap("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "Live grep" })
        keymap("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "Find buffers" })
        keymap("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "Help tags" })
        keymap("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>", { desc = "Recent files" })
        keymap("n", "<leader>fc", "<cmd>Telescope grep_string<CR>", { desc = "Find string under cursor" })
        keymap("n", "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "Document symbols" })
        keymap("n", "<leader>fS", "<cmd>Telescope lsp_workspace_symbols<CR>", { desc = "Workspace symbols" })

        -- LSP references
        keymap("n", "ga", "<cmd>Telescope lsp_references<CR>", { desc = "LSP references" })

        -- Document symbols
        keymap("n", "<leader>o", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "Document symbols" })

        -- Git
        keymap("n", "<leader>gc", "<cmd>Telescope git_status<CR>", { desc = "Git changed files" })
    end
}


