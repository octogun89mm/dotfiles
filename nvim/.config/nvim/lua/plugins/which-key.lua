return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function()
    local status, wk = pcall(require, "which-key")
    if not status then return end

    wk.setup({
      plugins = {
        marks = true,
        registers = true,
        spelling = { enabled = true, suggestions = 20 },
      },
      show_help = true,
    })
  end,
}
