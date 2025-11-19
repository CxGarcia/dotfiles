-- Harpoon 2: Lightning-fast file navigation
-- Mark your most important files and jump to them instantly
return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup({})

    -- Add current file to harpoon
    vim.keymap.set("n", "<leader>a", function()
      harpoon:list():add()
      vim.notify("File harpooned!", vim.log.levels.INFO)
    end, { desc = "Harpoon: Add file" })

    -- Toggle harpoon quick menu
    vim.keymap.set("n", "<C-e>", function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = "Harpoon: Toggle menu" })

    -- Jump to harpooned files with <leader>1-5
    -- Note: toggleterm bindings moved to <leader>t1-t4
    vim.keymap.set("n", "<leader>1", function()
      harpoon:list():select(1)
    end, { desc = "Harpoon: File 1" })

    vim.keymap.set("n", "<leader>2", function()
      harpoon:list():select(2)
    end, { desc = "Harpoon: File 2" })

    vim.keymap.set("n", "<leader>3", function()
      harpoon:list():select(3)
    end, { desc = "Harpoon: File 3" })

    vim.keymap.set("n", "<leader>4", function()
      harpoon:list():select(4)
    end, { desc = "Harpoon: File 4" })

    vim.keymap.set("n", "<leader>5", function()
      harpoon:list():select(5)
    end, { desc = "Harpoon: File 5" })

    -- Navigate to next/previous harpooned file
    vim.keymap.set("n", "<C-S-P>", function()
      harpoon:list():prev()
    end, { desc = "Harpoon: Previous" })

    vim.keymap.set("n", "<C-S-N>", function()
      harpoon:list():next()
    end, { desc = "Harpoon: Next" })
  end
}
