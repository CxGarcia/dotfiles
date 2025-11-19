-- Flash.nvim - Enhanced motion plugin (successor to leap.nvim)
return {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
        -- Disable labels (just like leap.nvim)
        labels = "asdfghjklqwertyuiopzxcvbnm",
        search = {
            -- Search mode: exact, search, fuzzy
            mode = "exact",
            -- Incremental search
            incremental = false,
        },
        jump = {
            -- Jump on first match
            jumplist = true,
            -- Jump position
            pos = "start",
            -- Automatically jump when there is only one match
            autojump = false,
        },
        label = {
            -- Show labels before or after the match
            before = true,
            after = true,
            -- Highlight current label
            current = true,
            -- Style: overlay, inline, eol
            style = "overlay",
        },
        modes = {
            -- Options for search mode
            search = {
                enabled = true,
            },
            char = {
                enabled = true,
                -- Show jump labels after typing a character
                jump_labels = true,
                -- Label multiple matches
                multi_line = true,
            },
        },
        -- Treesitter integration
        highlight = {
            backdrop = true,
        },
    },
    keys = {
        -- Main flash keybinding (s in normal/visual mode)
        {
            "s",
            mode = { "n", "x", "o" },
            function() require("flash").jump() end,
            desc = "Flash"
        },
        -- Flash treesitter (S in normal/visual/operator mode)
        {
            "S",
            mode = { "n", "x", "o" },
            function() require("flash").treesitter() end,
            desc = "Flash Treesitter"
        },
        -- Remote Flash (for operating on distant text)
        {
            "r",
            mode = "o",
            function() require("flash").remote() end,
            desc = "Remote Flash"
        },
        -- Treesitter search (visual mode search with treesitter)
        {
            "R",
            mode = { "o", "x" },
            function() require("flash").treesitter_search() end,
            desc = "Treesitter Search"
        },
        -- Toggle flash in search
        {
            "<c-s>",
            mode = { "c" },
            function() require("flash").toggle() end,
            desc = "Toggle Flash Search"
        },
    },
}
