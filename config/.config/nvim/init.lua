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
    checker = { enabled = false },
    change_detection = { notify = false }
})
