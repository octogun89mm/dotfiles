return {
  "milanglacier/minuet-ai.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("minuet").setup({
      provider = "openai_fim_compatible",
      n_completions = 1,
      context_window = 512,
      debounce = 300,
      throttle = 500,
      provider_options = {
        openai_fim_compatible = {
          api_key = "TERM",
          name = "llama.cpp",
          end_point = "http://localhost:3000/v1/completions",
          model = "PLACEHOLDER",
          optional = {
            max_tokens = 100,
            temperature = 0.2,
            top_p = 0.9,
          },
          template = {
            prompt = function(context_before_cursor, context_after_cursor, _)
              return "<|fim_prefix|>"
                .. context_before_cursor
                .. "<|fim_suffix|>"
                .. context_after_cursor
                .. "<|fim_middle|>"
            end,
            suffix = false,
          },
        },
      },
      virtualtext = {
        auto_trigger_ft = { "python", "lua", "javascript", "typescript", "rust", "go", "c", "cpp", "sh", "zsh", "bash", "html", "css" },
        show_on_completion_menu = false,
        keymap = {
          accept = "<A-a>",
          accept_line = "<A-l>",
          next = "<A-]>",
          prev = "<A-[>",
          dismiss = "<A-e>",
        },
      },
    })
  end,
}
