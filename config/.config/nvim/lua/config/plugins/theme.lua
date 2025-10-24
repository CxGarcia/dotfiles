-- Catppuccin Theme - A beautiful, modern color scheme
return {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
        require("catppuccin").setup({
            flavour = "mocha", -- latte, frappe, macchiato, mocha
            transparent_background = false,
            integrations = {
                telescope = true,
                treesitter = true,
                which_key = true,
                gitsigns = true,
                leap = true,
            }
        })
        vim.cmd.colorscheme("catppuccin")
    end
}


