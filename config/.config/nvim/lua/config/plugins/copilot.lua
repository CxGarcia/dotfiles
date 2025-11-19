return {
	"github/copilot.vim",
	-- Copilot.vim is a Vim script plugin
	-- Load on startup to ensure commands are available
	config = function()
		-- Disable default Tab mapping (we handle it in nvim-cmp)
		vim.g.copilot_no_tab_map = true
		-- Esc dismisses Copilot suggestion (default behavior)
		vim.g.copilot_assume_mapped = true
	end
}
