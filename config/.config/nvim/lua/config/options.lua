-- Core Neovim Options
local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- UI
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.showmode = false

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Clipboard
opt.clipboard = "unnamedplus"

-- Better completion
opt.completeopt = "menu,menuone,noselect"

-- Persistent undo
opt.undofile = true
opt.undolevels = 10000

-- Performance
opt.updatetime = 250
opt.timeoutlen = 300

-- Whitespace characters
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Mouse support
opt.mouse = "a"

-- Backup files
opt.backup = false
opt.writebackup = false
opt.swapfile = false

-- Shell configuration to load zsh with .zshrc
opt.shell = "/bin/zsh"
opt.shellcmdflag = "-i -c"

-- Session options (what gets saved in sessions)
opt.sessionoptions = {
    "buffers",    -- Save buffer list
    "curdir",     -- Save current directory
    "tabpages",   -- Save tab pages
    "winsize",    -- Save window sizes
    "winpos",     -- Save window positions
}
