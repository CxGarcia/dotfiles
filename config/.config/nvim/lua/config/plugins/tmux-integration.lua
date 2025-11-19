-- Seamless tmux and Neovim integration
return {
    "aserowy/tmux.nvim",
    event = "VeryLazy",
    config = function()
        require("tmux").setup({
            -- Copy/paste synchronization between Neovim instances via tmux
            copy_sync = {
                enable = true,
                -- Don't redirect to clipboard directly (let tmux-yank handle it)
                redirect_to_clipboard = false,
                -- Sync these registers with tmux buffers
                sync_registers = true,
                -- Sync delete operations
                sync_deletes = true,
                -- Sync unnamed register
                sync_unnamed = true,
            },
            -- Seamless navigation between tmux panes and vim splits
            navigation = {
                -- Use default C-h/j/k/l keybindings
                enable_default_keybindings = true,
                -- Don't cycle back to the first pane when at the last one
                cycle_navigation = false,
                -- Keep zoom state when navigating
                persist_zoom = true,
            },
            -- Resize panes with Alt+hjkl
            resize = {
                -- Enable default Alt+h/j/k/l keybindings for resize
                enable_default_keybindings = true,
                -- Resize step
                resize_step_x = 2,
                resize_step_y = 2,
            }
        })
    end
}
