return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("codecompanion").setup({
      adapters = {
        http = {
          llama_cpp = function()
            return require("codecompanion.adapters").extend("openai_compatible", {
              env = {
                url = "http://localhost:3000",
              },
              schema = {
                model = {
                  default = "qwen2.5-coder-14b-q4_k_m",
                },
              },
            })
          end,
        },
      },
      interactions = {
        chat = {
          adapter = "llama_cpp",
          opts = {
            system_prompt = function(ctx)
              return ctx.default_system_prompt
                .. "\n\n## MANDATORY CODE BLOCK RULES (NEVER VIOLATE THESE):"
                .. "\n1. ABSOLUTELY NO line number prefixes. Never start a line with a number followed by a pipe like '4 |' or '17 |'."
                .. "\n2. ABSOLUTELY NO placeholder comments like '// ...existing code...' or '// rest of code' or '/* ... */'. Never use ellipsis or abbreviations to skip code."
                .. "\n3. Code blocks must contain ONLY raw, valid, directly runnable code. No annotations, no markers, no metadata."
                .. "\n4. If showing a partial change, show only the relevant function or block — do not insert placeholder lines for omitted code."
            end,
          },
        },
        inline = {
          adapter = "llama_cpp",
        },
      },
    })
  end,
}
