-- Terminal management with toggleterm
return {
    "akinsho/toggleterm.nvim",
    version = "*",
    event = "VeryLazy",
    config = function()
        require("toggleterm").setup({
            -- Size of terminal
            size = function(term)
                if term.direction == "horizontal" then
                    return 15
                elseif term.direction == "vertical" then
                    return vim.o.columns * 0.4
                end
            end,

            -- Open terminal in insert mode
            open_mapping = [[<leader>tt]],

            -- Hide terminal line numbers
            hide_numbers = true,

            -- Shade terminal background
            shade_terminals = true,
            shading_factor = 2,

            -- Start terminals in insert mode
            start_in_insert = true,

            -- Close terminal when process exits
            close_on_exit = true,

            -- Shell to use
            shell = vim.o.shell,

            -- Persist terminal size
            persist_size = true,

            -- Persist terminal mode (insert/normal)
            persist_mode = true,

            -- Default direction
            direction = "float",

            -- Floating terminal settings
            float_opts = {
                border = "curved",
                width = math.floor(vim.o.columns * 0.8),
                height = math.floor(vim.o.lines * 0.8),
                winblend = 0,
                highlights = {
                    border = "Normal",
                    background = "Normal",
                },
            },
        })

        -- Terminal keymaps (only active in terminal mode)
        -- Uses buffer flags to conditionally apply keymaps
        function _G.set_terminal_keymaps()
            local bufnr = vim.api.nvim_get_current_buf()

            -- Skip keymaps for TUI applications (lazygit, claude, etc.)
            if vim.b[bufnr].skip_terminal_keymaps then
                return
            end

            local opts = { buffer = bufnr, silent = true }

            -- Easy escape from terminal mode (unless disabled)
            if not vim.b[bufnr].skip_escape_keymaps then
                vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
                vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
            end

            -- Window navigation from terminal (unless disabled)
            if not vim.b[bufnr].skip_nav_keymaps then
                vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
                vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
                vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
                vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
            end

            -- Close terminal (always available)
            vim.keymap.set('t', '<C-w>', [[<C-\><C-n><Cmd>close<CR>]], opts)
        end

        -- Apply terminal keymaps automatically
        vim.api.nvim_create_autocmd("TermOpen", {
            pattern = "term://*",
            callback = function()
                set_terminal_keymaps()
            end
        })

        -- Custom terminal commands
        local Terminal = require("toggleterm.terminal").Terminal

        -- Floating terminal (default)
        local function toggle_float_term()
            vim.cmd("ToggleTerm direction=float")
        end

        -- Horizontal terminal
        local function toggle_horizontal_term()
            vim.cmd("ToggleTerm direction=horizontal")
        end

        -- Vertical terminal
        local function toggle_vertical_term()
            vim.cmd("ToggleTerm direction=vertical")
        end

        -- Lazygit integration
        local lazygit = Terminal:new({
            cmd = "lazygit",
            dir = "git_dir",
            direction = "float",
            hidden = true,
            float_opts = {
                border = "curved",
                width = math.floor(vim.o.columns * 0.9),
                height = math.floor(vim.o.lines * 0.9),
            },
            on_open = function(term)
                vim.cmd("startinsert!")
                -- Mark buffer to skip conflicting keymaps
                vim.b[term.bufnr].skip_escape_keymaps = true
                vim.b[term.bufnr].skip_nav_keymaps = true
            end,
        })

        function _G.toggle_lazygit()
            lazygit:toggle()
        end

        -- Node REPL (uses default keymaps - can navigate and escape)
        local node = Terminal:new({
            cmd = "node",
            hidden = true,
            direction = "float",
            on_open = function(term)
                vim.cmd("startinsert!")
                -- No flags set = gets all default keymaps
            end,
        })

        function _G.toggle_node()
            node:toggle()
        end

        -- Python REPL (uses default keymaps - can navigate and escape)
        local python = Terminal:new({
            cmd = "python3",
            hidden = true,
            direction = "float",
            on_open = function(term)
                vim.cmd("startinsert!")
                -- No flags set = gets all default keymaps
            end,
        })

        function _G.toggle_python()
            python:toggle()
        end

        -- Claude Code (TUI app - skip conflicting keymaps)
        local claude = Terminal:new({
            cmd = "claude",
            direction = "float",
            hidden = true,
            float_opts = {
                border = "curved",
                width = math.floor(vim.o.columns * 0.9),
                height = math.floor(vim.o.lines * 0.9),
            },
            on_open = function(term)
                vim.cmd("startinsert!")
                -- Mark buffer to skip conflicting keymaps
                vim.b[term.bufnr].skip_escape_keymaps = true
                vim.b[term.bufnr].skip_nav_keymaps = true
            end,
        })

        function _G.toggle_claude()
            claude:toggle()
        end

        -- Keybindings
        local opts = { noremap = true, silent = true }

        -- Toggle terminals - Normal mode
        vim.keymap.set("n", "<C-,>", toggle_claude, vim.tbl_extend("force", opts, { desc = "Toggle Claude Code" }))
        vim.keymap.set("n", "<leader>tt", toggle_float_term, vim.tbl_extend("force", opts, { desc = "Toggle floating terminal" }))
        vim.keymap.set("n", "<leader>th", toggle_horizontal_term, vim.tbl_extend("force", opts, { desc = "Toggle horizontal terminal" }))
        vim.keymap.set("n", "<leader>tv", toggle_vertical_term, vim.tbl_extend("force", opts, { desc = "Toggle vertical terminal" }))

        -- Toggle terminals - Terminal mode (won't interfere with typing)
        vim.keymap.set("t", "<C-,>", toggle_claude, vim.tbl_extend("force", opts, { desc = "Toggle Claude Code" }))
        vim.keymap.set("t", "<A-h>", toggle_horizontal_term, vim.tbl_extend("force", opts, { desc = "Toggle horizontal terminal" }))
        vim.keymap.set("t", "<A-v>", toggle_vertical_term, vim.tbl_extend("force", opts, { desc = "Toggle vertical terminal" }))

        -- Special terminals - Normal mode only
        vim.keymap.set("n", "<leader>cc", "<cmd>lua toggle_claude()<CR>", vim.tbl_extend("force", opts, { desc = "Toggle Claude Code" }))
        vim.keymap.set("n", "<leader>gg", "<cmd>lua toggle_lazygit()<CR>", vim.tbl_extend("force", opts, { desc = "Toggle lazygit" }))
        vim.keymap.set("n", "<leader>tn", "<cmd>lua toggle_node()<CR>", vim.tbl_extend("force", opts, { desc = "Toggle Node REPL" }))
        vim.keymap.set("n", "<leader>tp", "<cmd>lua toggle_python()<CR>", vim.tbl_extend("force", opts, { desc = "Toggle Python REPL" }))

        -- Terminal selection
        vim.keymap.set("n", "<leader>ta", "<cmd>ToggleTermToggleAll<CR>", vim.tbl_extend("force", opts, { desc = "Toggle all terminals" }))
        vim.keymap.set("n", "<leader>1", "<cmd>1ToggleTerm<CR>", vim.tbl_extend("force", opts, { desc = "Toggle terminal 1" }))
        vim.keymap.set("n", "<leader>2", "<cmd>2ToggleTerm<CR>", vim.tbl_extend("force", opts, { desc = "Toggle terminal 2" }))
        vim.keymap.set("n", "<leader>3", "<cmd>3ToggleTerm<CR>", vim.tbl_extend("force", opts, { desc = "Toggle terminal 3" }))
        vim.keymap.set("n", "<leader>4", "<cmd>4ToggleTerm<CR>", vim.tbl_extend("force", opts, { desc = "Toggle terminal 4" }))
    end,
}
