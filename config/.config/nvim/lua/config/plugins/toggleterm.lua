-- Terminal management with toggleterm
return {
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        event = "VeryLazy",
        dependencies = {
            "ryanmsnyder/toggleterm-manager.nvim",
        },
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

            -- Always start in insert mode (don't persist the last mode)
            persist_mode = false,

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

            -- Skip keymaps for TUI applications (claude, etc.)
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
            -- Only horizontal navigation - vertical keys reserved for scrolling
            if not vim.b[bufnr].skip_nav_keymaps then
                vim.keymap.set('t', '<C-h>', [[<C-\><C-n><C-w>h]], opts)
                vim.keymap.set('t', '<C-l>', [[<C-\><C-n><C-w>l]], opts)
            end

            -- Close terminal (always available)
            vim.keymap.set('t', '<C-w>', [[<C-\><C-n><Cmd>close<CR>]], opts)
        end

        -- Apply terminal keymaps automatically
        vim.api.nvim_create_autocmd("TermOpen", {
            pattern = "term://*",
            callback = function()
                local bufnr = vim.api.nvim_get_current_buf()
                local cmd = vim.api.nvim_buf_get_name(bufnr)

                -- List of TUI apps that need native keybindings
                local tui_apps = { "lazygit", "htop", "ranger", "k9s", "btm", "lazydocker", "ncdu" }

                -- Check if this is a TUI app
                for _, app in ipairs(tui_apps) do
                    if cmd:match(app) then
                        vim.b[bufnr].skip_terminal_keymaps = true
                        return
                    end
                end

                -- Regular terminal - apply keymaps
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

        -- Claude Code - Embedded terminal that attaches to a nested tmux session
        -- This gives us:
        -- 1. Embedded panel (stays in nvim, doesn't switch sessions)
        -- 2. Persistent tmux session (survives nvim restarts)
        -- 3. Child of parent session (dies when parent tmux session dies)

        -- Helper function to ensure Claude tmux session exists
        local function ensure_claude_session()
            local cwd = vim.fn.getcwd()
            local basename = vim.fn.fnamemodify(cwd, ":t"):gsub("%.", "_")
            local session_name = basename .. "-claude"

            -- Check if session exists
            local check_result = vim.fn.system("tmux has-session -t " .. vim.fn.shellescape(session_name) .. " 2>/dev/null")

            if vim.v.shell_error ~= 0 then
                -- Session doesn't exist, create it as a detached session
                vim.fn.system(string.format(
                    "tmux new-session -d -s %s -c %s",
                    vim.fn.shellescape(session_name),
                    vim.fn.shellescape(cwd)
                ))
                -- Disable status bar for this session
                vim.fn.system(string.format(
                    "tmux set-option -t %s status off",
                    vim.fn.shellescape(session_name)
                ))
                -- Start Claude Code with skip permissions flag
                vim.fn.system(string.format(
                    "tmux send-keys -t %s:1 'claude --dangerously-skip-permissions' C-m",
                    vim.fn.shellescape(session_name)
                ))
            end

            return session_name
        end

        local claude = Terminal:new({
            -- Use a shell wrapper that calls the helper function
            cmd = function()
                local session_name = ensure_claude_session()
                return "tmux attach-session -t " .. session_name
            end,
            direction = "float",
            hidden = true,
            float_opts = {
                border = "curved",
                width = math.floor(vim.o.columns * 0.9),
                height = math.floor(vim.o.lines * 0.9),
            },
            on_open = function(term)
                vim.cmd("startinsert!")
                -- Skip window navigation keymaps (Claude needs these keys)
                vim.b[term.bufnr].skip_nav_keymaps = true

                -- In normal mode, send <esc> to Claude to cancel operations
                vim.keymap.set('n', '<esc>', function()
                    vim.api.nvim_chan_send(vim.b.terminal_job_id, '\x1b')
                end, { buffer = term.bufnr, silent = true })
            end,
        })

        local function toggle_claude()
            -- Ensure session exists before toggling
            ensure_claude_session()
            claude:toggle()
        end

        -- Keybindings
        local opts = { noremap = true, silent = true }

        -- Toggle terminals - Normal mode
        vim.keymap.set("n", "<M-,>", toggle_claude, vim.tbl_extend("force", opts, { desc = "Toggle Claude Code" }))
        vim.keymap.set("n", "<leader>tt", toggle_float_term, vim.tbl_extend("force", opts, { desc = "Toggle floating terminal" }))
        vim.keymap.set("n", "<leader>th", toggle_horizontal_term, vim.tbl_extend("force", opts, { desc = "Toggle horizontal terminal" }))
        vim.keymap.set("n", "<leader>tv", toggle_vertical_term, vim.tbl_extend("force", opts, { desc = "Toggle vertical terminal" }))

        -- Toggle terminals - Terminal mode (won't interfere with typing)
        vim.keymap.set("t", "<M-,>", toggle_claude, vim.tbl_extend("force", opts, { desc = "Toggle Claude Code" }))
        vim.keymap.set("t", "<A-h>", toggle_horizontal_term, vim.tbl_extend("force", opts, { desc = "Toggle horizontal terminal" }))
        vim.keymap.set("t", "<A-v>", toggle_vertical_term, vim.tbl_extend("force", opts, { desc = "Toggle vertical terminal" }))

        -- Special terminals - Normal mode only
        vim.keymap.set("n", "<leader>cc", toggle_claude, vim.tbl_extend("force", opts, { desc = "Toggle Claude Code" }))
        vim.keymap.set("n", "<leader>tn", "<cmd>lua toggle_node()<CR>", vim.tbl_extend("force", opts, { desc = "Toggle Node REPL" }))
        vim.keymap.set("n", "<leader>tp", "<cmd>lua toggle_python()<CR>", vim.tbl_extend("force", opts, { desc = "Toggle Python REPL" }))

        -- Terminal selection
        -- Note: Changed from <leader>1-4 to <leader>t1-t4 to avoid conflict with Harpoon
        vim.keymap.set("n", "<leader>ta", "<cmd>ToggleTermToggleAll<CR>", vim.tbl_extend("force", opts, { desc = "Toggle all terminals" }))
        vim.keymap.set("n", "<leader>t1", "<cmd>1ToggleTerm<CR>", vim.tbl_extend("force", opts, { desc = "Toggle terminal 1" }))
        vim.keymap.set("n", "<leader>t2", "<cmd>2ToggleTerm<CR>", vim.tbl_extend("force", opts, { desc = "Toggle terminal 2" }))
        vim.keymap.set("n", "<leader>t3", "<cmd>3ToggleTerm<CR>", vim.tbl_extend("force", opts, { desc = "Toggle terminal 3" }))
        vim.keymap.set("n", "<leader>t4", "<cmd>4ToggleTerm<CR>", vim.tbl_extend("force", opts, { desc = "Toggle terminal 4" }))

        -- ============================================================
        -- Named Purpose Terminals (tests, server, git)
        -- ============================================================

        -- Tests terminal (dedicated for running tests)
        local tests_term = Terminal:new({
            cmd = vim.o.shell,
            hidden = true,
            direction = "horizontal",
            count = 10, -- Use high count to avoid conflicts
            display_name = "Tests",
            on_open = function(term)
                vim.cmd("startinsert!")
            end,
        })

        function _G.toggle_tests()
            tests_term:toggle()
        end

        -- Server terminal (for dev servers)
        local server_term = Terminal:new({
            cmd = vim.o.shell,
            hidden = true,
            direction = "horizontal",
            count = 11,
            display_name = "Server",
            on_open = function(term)
                vim.cmd("startinsert!")
            end,
        })

        function _G.toggle_server()
            server_term:toggle()
        end

        -- Git terminal (for git operations)
        local git_term = Terminal:new({
            cmd = vim.o.shell,
            hidden = true,
            direction = "float",
            count = 12,
            display_name = "Git",
            on_open = function(term)
                vim.cmd("startinsert!")
            end,
        })

        function _G.toggle_git()
            git_term:toggle()
        end

        -- Named terminal keybindings
        vim.keymap.set("n", "<leader>tT", "<cmd>lua toggle_tests()<CR>", vim.tbl_extend("force", opts, { desc = "Toggle Tests terminal" }))
        vim.keymap.set("n", "<leader>ts", "<cmd>lua toggle_server()<CR>", vim.tbl_extend("force", opts, { desc = "Toggle Server terminal" }))
        vim.keymap.set("n", "<leader>tg", "<cmd>lua toggle_git()<CR>", vim.tbl_extend("force", opts, { desc = "Toggle Git terminal" }))

        -- ============================================================
        -- Split Layout Functions (side-by-side terminals)
        -- ============================================================

        -- Open 2 terminals side by side
        local function layout_double()
            local width = math.floor(vim.o.columns * 0.4)
            vim.cmd("2ToggleTerm direction=vertical size=" .. width)
            vim.defer_fn(function()
                vim.cmd("3ToggleTerm direction=vertical size=" .. width)
            end, 100)
        end

        -- Open 3-pane layout: editor + 2 terminals
        local function layout_triple()
            vim.cmd("2ToggleTerm direction=vertical size=60")
            vim.defer_fn(function()
                vim.cmd("3ToggleTerm direction=vertical size=60")
            end, 100)
        end

        -- Layout keybindings
        vim.keymap.set("n", "<leader>tL", layout_double, vim.tbl_extend("force", opts, { desc = "Layout: 2 terminals side-by-side" }))
        vim.keymap.set("n", "<leader>t#", layout_triple, vim.tbl_extend("force", opts, { desc = "Layout: 3-pane (editor + 2 terms)" }))

        -- ============================================================
        -- Terminal Navigation (cycling)
        -- ============================================================

        -- Track current terminal index for cycling
        local current_term_idx = 1
        local max_terms = 4

        local function next_terminal()
            current_term_idx = current_term_idx % max_terms + 1
            vim.cmd(current_term_idx .. "ToggleTerm")
        end

        local function prev_terminal()
            current_term_idx = (current_term_idx - 2) % max_terms + 1
            vim.cmd(current_term_idx .. "ToggleTerm")
        end

        vim.keymap.set("n", "<leader>t]", next_terminal, vim.tbl_extend("force", opts, { desc = "Next terminal" }))
        vim.keymap.set("n", "<leader>t[", prev_terminal, vim.tbl_extend("force", opts, { desc = "Previous terminal" }))

        -- ============================================================
        -- Toggleterm Manager Setup (Telescope integration)
        -- ============================================================

        require("toggleterm-manager").setup({
            titles = {
                prompt = "Terminals",
                results = "Results",
            },
            mappings = {
                i = {
                    ["<CR>"] = { action = require("toggleterm-manager").actions.toggle_term, exit_on_action = true },
                    ["<C-d>"] = { action = require("toggleterm-manager").actions.delete_term, exit_on_action = false },
                    ["<C-r>"] = { action = require("toggleterm-manager").actions.rename_term, exit_on_action = false },
                },
                n = {
                    ["<CR>"] = { action = require("toggleterm-manager").actions.toggle_term, exit_on_action = true },
                    ["d"] = { action = require("toggleterm-manager").actions.delete_term, exit_on_action = false },
                    ["r"] = { action = require("toggleterm-manager").actions.rename_term, exit_on_action = false },
                },
            },
        })

        -- Terminal picker keybinding
        vim.keymap.set("n", "<leader>tf", "<cmd>Telescope toggleterm_manager<CR>", vim.tbl_extend("force", opts, { desc = "Terminal picker (Telescope)" }))
    end,
    },
}
