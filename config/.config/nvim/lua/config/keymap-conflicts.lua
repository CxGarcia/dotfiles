-- Keybinding conflict detection utility
-- This module helps detect and report keybinding conflicts early

local M = {}

-- Get all current keymaps for a given mode
local function get_keymaps(mode)
    local keymaps = vim.api.nvim_get_keymap(mode)
    local buf_keymaps = vim.api.nvim_buf_get_keymap(0, mode)

    -- Combine global and buffer-local keymaps
    local all_keymaps = {}
    for _, keymap in ipairs(keymaps) do
        table.insert(all_keymaps, keymap)
    end
    for _, keymap in ipairs(buf_keymaps) do
        table.insert(all_keymaps, keymap)
    end

    return all_keymaps
end

-- Find conflicts in keymaps
function M.find_conflicts()
    local modes = { "n", "i", "v", "x", "s", "o", "t", "c" }
    local conflicts = {}

    for _, mode in ipairs(modes) do
        local keymaps = get_keymaps(mode)
        local seen = {}

        for _, keymap in ipairs(keymaps) do
            local lhs = keymap.lhs
            if seen[lhs] then
                -- Found a conflict
                if not conflicts[mode] then
                    conflicts[mode] = {}
                end
                if not conflicts[mode][lhs] then
                    conflicts[mode][lhs] = { seen[lhs] }
                end
                table.insert(conflicts[mode][lhs], keymap)
            else
                seen[lhs] = keymap
            end
        end
    end

    return conflicts
end

-- Format conflict information for display
local function format_conflicts(conflicts)
    if vim.tbl_isempty(conflicts) then
        return "No keybinding conflicts detected!"
    end

    local lines = { "Keybinding Conflicts Detected:", "" }

    for mode, mode_conflicts in pairs(conflicts) do
        table.insert(lines, string.format("Mode: %s", mode))
        for lhs, maps in pairs(mode_conflicts) do
            table.insert(lines, string.format("  %s:", lhs))
            for i, map in ipairs(maps) do
                local desc = map.desc or "no description"
                local rhs = map.rhs or map.callback and "<callback>" or "<unknown>"
                table.insert(lines, string.format("    %d. %s -> %s", i, desc, rhs))
            end
        end
        table.insert(lines, "")
    end

    return table.concat(lines, "\n")
end

-- Display conflicts in a floating window
function M.show_conflicts()
    local conflicts = M.find_conflicts()
    local content = format_conflicts(conflicts)

    -- Create a buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")

    -- Calculate window size
    local width = 80
    local height = 20
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    -- Create window
    local opts = {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded"
    }

    local win = vim.api.nvim_open_win(buf, true, opts)

    -- Set up keybinding to close the window
    vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { noremap = true, silent = true })
end

-- Check for conflicts and notify on startup
function M.check_on_startup()
    -- Delay the check to allow all plugins to load
    vim.defer_fn(function()
        local conflicts = M.find_conflicts()
        if not vim.tbl_isempty(conflicts) then
            local count = 0
            for _, mode_conflicts in pairs(conflicts) do
                for _, _ in pairs(mode_conflicts) do
                    count = count + 1
                end
            end
            vim.notify(
                string.format("Warning: %d keybinding conflict(s) detected! Run :KeymapConflicts to see details.", count),
                vim.log.levels.WARN
            )
        end
    end, 1000) -- Wait 1 second after startup
end

-- List all keymaps with a specific prefix (e.g., "<leader>g")
function M.list_prefix(prefix, mode)
    mode = mode or "n"
    local keymaps = get_keymaps(mode)
    local matches = {}

    for _, keymap in ipairs(keymaps) do
        if vim.startswith(keymap.lhs, prefix) then
            table.insert(matches, keymap)
        end
    end

    -- Sort by lhs
    table.sort(matches, function(a, b) return a.lhs < b.lhs end)

    -- Format output
    local lines = { string.format("Keymaps starting with '%s' in mode '%s':", prefix, mode), "" }
    for _, map in ipairs(matches) do
        local desc = map.desc or "no description"
        local rhs = map.rhs or map.callback and "<callback>" or "<unknown>"
        table.insert(lines, string.format("  %-20s -> %-30s (%s)", map.lhs, desc, rhs))
    end

    if #matches == 0 then
        table.insert(lines, "  No keymaps found")
    end

    print(table.concat(lines, "\n"))
end

-- Show what a specific keybinding does
function M.show_keymap(key, mode)
    mode = mode or "n"

    -- Get all keymaps
    local keymaps = get_keymaps(mode)
    local matches = {}

    for _, keymap in ipairs(keymaps) do
        if keymap.lhs == key then
            table.insert(matches, keymap)
        end
    end

    if #matches == 0 then
        print(string.format("No keymap found for '%s' in mode '%s'", key, mode))
        return
    end

    -- Format output
    local lines = { string.format("Keymap '%s' in mode '%s':", key, mode), "" }
    for i, map in ipairs(matches) do
        local desc = map.desc or "no description"
        local rhs = map.rhs or map.callback and "<callback>" or "<unknown>"
        local buffer = map.buffer and "buffer-local" or "global"
        local source = map.sid or "unknown"

        table.insert(lines, string.format("Match #%d:", i))
        table.insert(lines, string.format("  Description: %s", desc))
        table.insert(lines, string.format("  Maps to: %s", rhs))
        table.insert(lines, string.format("  Scope: %s", buffer))
        table.insert(lines, string.format("  Silent: %s", map.silent and "yes" or "no"))
        table.insert(lines, string.format("  Noremap: %s", map.noremap and "yes" or "no"))
        table.insert(lines, "")
    end

    print(table.concat(lines, "\n"))
end

-- Export the module
return M
