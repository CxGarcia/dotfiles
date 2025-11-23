-- Enable faster Lua module loader (Neovim 0.9+)
-- Must be set before any require() calls for maximum benefit
vim.loader.enable()

-- Disable unused providers (saves 10-20ms startup time)
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

-- Set leader key to space (must be set before lazy)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Bootstrap lazy.nvim package manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath
    })
end
vim.opt.rtp:prepend(lazypath)

-- Load core settings
require("config.options")
require("config.keymaps")

-- Load plugins
require("lazy").setup("config.plugins", {
    defaults = {
        lazy = true, -- Make all plugins lazy by default
    },
    checker = { enabled = false },
    change_detection = { notify = false },
    performance = {
        rtp = {
            disabled_plugins = {
                "gzip",
                "matchit",
                -- "matchparen" kept enabled - useful for showing matching brackets
                "netrwPlugin",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zipPlugin",
            },
        },
    },
    ui = {
        border = "rounded",
    },
})

-- Load keymap conflict detection
local keymap_conflicts = require("config.keymap-conflicts")

-- Note: Automatic conflict checking disabled for performance (saves 50-100ms)
-- Run :KeymapConflicts manually to check for conflicts when needed
-- keymap_conflicts.check_on_startup()

-- Create user commands for keymap conflict detection
vim.api.nvim_create_user_command("KeymapConflicts", function()
    keymap_conflicts.show_conflicts()
end, { desc = "Show keybinding conflicts" })

vim.api.nvim_create_user_command("KeymapList", function(opts)
    local prefix = opts.args ~= "" and opts.args or "<leader>"
    keymap_conflicts.list_prefix(prefix)
end, { nargs = "?", desc = "List keymaps with a prefix (default: <leader>)" })

vim.api.nvim_create_user_command("KeymapShow", function(opts)
    if opts.args == "" then
        print("Usage: :KeymapShow <key> [mode]")
        print("Example: :KeymapShow <leader>gc")
        print("Example: :KeymapShow <leader>gc n")
        return
    end
    local parts = vim.split(opts.args, " ")
    local key = parts[1]
    local mode = parts[2] or "n"
    keymap_conflicts.show_keymap(key, mode)
end, { nargs = "*", desc = "Show what a specific keybinding does" })
