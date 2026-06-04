return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "hrsh7th/cmp-nvim-lsp",
  },

  config = function()
    local capabilities = require("cmp_nvim_lsp").default_capabilities()
    local mason = require("mason")

    -- =========================
    -- Setup Mason
    -- =========================
    mason.setup()

    -- =========================
    -- Lua LSP
    -- =========================
    vim.lsp.config.lua_ls = {
      capabilities = capabilities,
      settings = {
        Lua = {
          diagnostics = { globals = { "vim" } },
          workspace = {
            library = vim.api.nvim_get_runtime_file("", true),
            checkThirdParty = false
          },
          telemetry = { enable = false }
        }
      }
    }

    -- =========================
    -- Python and JSON LSP
    -- =========================
    vim.lsp.config.pyright = { capabilities = capabilities }
    vim.lsp.config.jsonls = { capabilities = capabilities }

    -- =========================
    -- Ruff (Python linter + formatter)
    -- =========================
    -- Ruff runs alongside pyright: pyright handles type checking,
    -- ruff handles PEP 8 style linting, import sorting, and formatting.
    vim.lsp.config.ruff = {
      capabilities = capabilities,
      init_options = {
        settings = {
          lint = {
            -- E: pycodestyle errors (PEP 8)
            -- W: pycodestyle warnings (PEP 8)
            -- F: Pyflakes (unused imports, undefined names, etc.)
            -- I: isort (import sorting per PEP 8)
            select = { "E", "W", "F", "I" },
          },
        },
      },
      -- Disable ruff's hover — pyright provides better hover info
      on_attach = function(client, _)
        client.server_capabilities.hoverProvider = false
      end,
    }

    -- =========================
    -- Enable default servers
    -- =========================
    vim.lsp.config.html = { capabilities = capabilities }
    vim.lsp.config.qmlls = {
      capabilities = capabilities,
      cmd = { "/usr/lib/qt6/bin/qmlls", "-E", "-I", "/usr/lib/qt6/qml" },
      filetypes = { "qml" },
      root_dir = function(bufnr)
        return vim.fs.root(bufnr, { ".git" })
          or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":h")
      end,
    }

    vim.lsp.enable{ "lua_ls", "pyright", "jsonls", "ruff", "html", "qmlls" }

    -- =========================
    -- Web CSS LSP with Waybar exclusion
    -- =========================
    vim.lsp.config.cssls = {
      capabilities = capabilities,
      settings = {
        css = { validate = true },
        scss = { validate = true },
        less = { validate = true }
      },
      filetypes = { "css", "scss", "less" },
      on_attach = function(client, bufnr)
        local path = vim.api.nvim_buf_get_name(bufnr)
        -- Stop this client if it's a Waybar CSS file
        if path:match("waybar") then
          client.stop()
        end
      end
    }

    -- =========================
    -- GTK CSS (Waybar) LSP
    -- =========================
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "css",
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        local path = vim.api.nvim_buf_get_name(buf)

        if not path:match("waybar") then
          return
        end

        -- Only start cssls-gtk if not already attached
        for _, client in pairs(vim.lsp.get_clients({ bufnr = buf })) do
          if client.name == "cssls-gtk" then
            return
          end
        end

        vim.lsp.start{
          name = "cssls-gtk",
          cmd = { "vscode-css-language-server", "--stdio" },
          root_dir = vim.fn.fnamemodify(path, ":h"),
          settings = {
            css = { validate = false },
            scss = { validate = false },
            less = { validate = false }
          }
        }
      end
    })
  end
}
