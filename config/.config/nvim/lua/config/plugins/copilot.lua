return {
	"github/copilot.vim",
	event = "InsertEnter",
	config = function()
		-- Disable default Tab mapping (we handle it in nvim-cmp)
		vim.g.copilot_no_tab_map = true

		-- Disable for large files to prevent hangs
		vim.api.nvim_create_autocmd("BufReadPre", {
			callback = function()
				local file_size = vim.fn.getfsize(vim.fn.expand("%"))
				if file_size > 100000 or file_size == -2 then
					vim.b.copilot_enabled = false
				end
			end,
		})
	end
}
