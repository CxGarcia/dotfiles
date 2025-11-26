-- Flash.nvim - Enhanced f/F/t/T motions and / search
return {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
        labels = "asdfghjklqwertyuiopzxcvbnm",
        search = {
            mode = "exact",
            incremental = true,
        },
        jump = {
            jumplist = true,
            pos = "start",
            autojump = true, -- Auto-jump when only one match
        },
        label = {
            after = true,
            before = false,
            current = true,
            style = "overlay",
        },
        modes = {
            -- Enhanced / search with flash labels
            search = {
                enabled = true,
            },
            -- Enhanced f/F/t/T with jump labels
            char = {
                enabled = true,
                jump_labels = true,
                multi_line = true,
                keys = { "f", "F", "t", "T" }, -- Explicitly only these keys
            },
        },
        highlight = {
            backdrop = true,
        },
    },
    keys = {
        -- Toggle flash labels in / search
        {
            "<c-s>",
            mode = { "c" },
            function() require("flash").toggle() end,
            desc = "Toggle Flash Search"
        },
    },
}
