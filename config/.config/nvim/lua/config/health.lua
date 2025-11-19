-- Health check for keybinding conflicts
local M = {}

function M.check()
    vim.health.start("Keybinding Conflicts")

    local conflicts_module = require("config.keymap-conflicts")
    local conflicts = conflicts_module.find_conflicts()

    if vim.tbl_isempty(conflicts) then
        vim.health.ok("No keybinding conflicts detected")
    else
        local count = 0
        for mode, mode_conflicts in pairs(conflicts) do
            for lhs, maps in pairs(mode_conflicts) do
                count = count + 1
                local desc = string.format("Mode '%s': '%s' has %d conflicting mappings", mode, lhs, #maps)
                vim.health.warn(desc)
                for i, map in ipairs(maps) do
                    local map_desc = map.desc or "no description"
                    vim.health.info(string.format("  %d. %s", i, map_desc))
                end
            end
        end
        vim.health.warn(string.format("Total conflicts: %d", count))
        vim.health.info("Run :KeymapConflicts to see full details")
    end

    vim.health.start("Keybinding Debug Commands")
    vim.health.info("Available commands:")
    vim.health.info("  :KeymapConflicts - Show all keybinding conflicts in a floating window")
    vim.health.info("  :KeymapList [prefix] - List all keymaps with a prefix (default: <leader>)")
    vim.health.info("  :KeymapShow <key> [mode] - Show what a specific keybinding does")
    vim.health.ok("Debug commands are available")
end

return M
