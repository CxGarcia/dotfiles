-- Session persistence configuration
return {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {
        dir = vim.fn.stdpath("state") .. "/sessions/",
        need = 1,      -- Minimum file buffers to trigger save
        branch = true  -- Use git branch in session naming
    },
    keys = {
        {
            "<leader>ss",
            function() require("persistence").load() end,
            desc = "Restore Session"
        },
        {
            "<leader>sl",
            function() require("persistence").load({ last = true }) end,
            desc = "Restore Last Session"
        },
        {
            "<leader>sd",
            function() require("persistence").stop() end,
            desc = "Don't Save Current Session"
        }
    }
}
