-- Telescope tmux integration for session switching from nvim
return {
    "camgraff/telescope-tmux.nvim",
    dependencies = {
        "nvim-telescope/telescope.nvim",
        "nvim-lua/plenary.nvim",
    },
    config = function()
        local telescope = require("telescope")

        -- Load the extension
        telescope.load_extension("tmux")

        -- Keybindings
        local keymap = vim.keymap.set
        local opts = { noremap = true, silent = true }

        -- Session switcher - <leader>ts (tmux sessions)
        keymap(
            "n",
            "<leader>ts",
            "<cmd>Telescope tmux sessions<CR>",
            vim.tbl_extend("force", opts, { desc = "Tmux: Switch session" })
        )

        -- Session switcher - <C-a> (receives from tmux when you press Ctrl-a Ctrl-a)
        -- When you press Ctrl-a Ctrl-a: first Ctrl-a is tmux prefix, second sends Ctrl-a to nvim
        keymap(
            "n",
            "<C-a>",
            "<cmd>Telescope tmux sessions<CR>",
            vim.tbl_extend("force", opts, { desc = "Tmux: Switch session" })
        )

        -- Window switcher - <leader>tw (tmux windows)
        keymap(
            "n",
            "<leader>tw",
            "<cmd>Telescope tmux windows<CR>",
            vim.tbl_extend("force", opts, { desc = "Tmux: Switch window" })
        )
    end
}
