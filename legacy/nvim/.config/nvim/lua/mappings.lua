local wk = require("which-key")

-- =========================================================
-- INLINE FLOATING PROMPT FOR CODECOMPANION
-- =========================================================
local function inline_prompt_float()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "markdown"

  local width = math.floor(vim.o.columns * 0.6)
  local height = 12
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    style = "minimal",
    border = "single",
    title = " AI Inline Prompt ",
    title_pos = "center",
  })

  vim.cmd("startinsert")

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end

  local function submit()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local prompt = table.concat(lines, "\n")
    close()
    if prompt ~= "" then
      require("codecompanion").inline({ args = prompt })
    end
  end

  vim.keymap.set("n", "<CR>", submit, { buffer = buf, nowait = true })
  vim.keymap.set({ "n", "i" }, "<C-s>", submit, { buffer = buf, nowait = true })
  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
end

-- =========================================================
-- WHICH-KEY GROUPS & KEYBINDS
-- =========================================================
wk.add({
  { "<leader>f", group = "Find (Telescope)" },
  { "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Find files" },
  { "<leader>fb", function() require("telescope.builtin").buffers() end, desc = "List buffers" },
  
  { "<leader>e", group = "File Explorer" },
  { "<leader>ex", function()
      require('telescope').extensions.file_browser.file_browser({
        path = vim.fn.expand('%:p:h'),
        select_buffer = true,
      })
    end, desc = "File browser in current directory"
  },
  
  { "<leader>b", group = "Buffers" },
  { "<leader>bn", ":bnext<CR>", desc = "Next buffer" },
  { "<leader>bp", ":bprevious<CR>", desc = "Previous buffer" },
  { "<leader>zm", ":ZenMode<CR>", desc = "Toggle ZenMode" },
  
  { "<leader>a", group = "AI (CodeCompanion)" },
  { "<leader>aa", "<cmd>CodeCompanionActions<CR>", desc = "Actions menu", mode = {"n", "v"} },
  { "<leader>ac", "<cmd>CodeCompanionChat Toggle<CR>", desc = "Toggle chat" },
  { "<leader>ai", "<cmd>CodeCompanion<CR>", desc = "Inline prompt", mode = "v" },
  { "<leader>ap", inline_prompt_float, desc = "Prompt float (inline)" },

  { "<leader>nhl", "<cmd>nohl<CR>", desc = "Clear search highlight" },

  -- LSP
  { "<leader>l", group = "LSP" },
  { "<leader>lr", vim.lsp.buf.rename, desc = "Rename symbol" },
  { "<leader>la", vim.lsp.buf.code_action, desc = "Code action", mode = { "n", "v" } },
  { "<leader>lf", vim.lsp.buf.format, desc = "Format buffer" },
  { "<leader>ld", vim.diagnostic.open_float, desc = "Line diagnostics" },
  { "<leader>li", "<cmd>LspInfo<CR>", desc = "LSP info" },

  -- LSP navigation (standard keys)
  { "gd", vim.lsp.buf.definition, desc = "Go to definition" },
  { "gD", vim.lsp.buf.declaration, desc = "Go to declaration" },
  { "gr", vim.lsp.buf.references, desc = "References" },
  { "gi", vim.lsp.buf.implementation, desc = "Go to implementation" },
  { "K", vim.lsp.buf.hover, desc = "Hover documentation" },

  -- Diagnostic navigation
  { "[d", vim.diagnostic.goto_prev, desc = "Previous diagnostic" },
  { "]d", vim.diagnostic.goto_next, desc = "Next diagnostic" },

  -- Git
  { "<leader>g", group = "Git" },
  { "<leader>gs", function() require("neogit").open() end, desc = "Neogit status" },
  { "<leader>gc", function() require("neogit").open({ "commit" }) end, desc = "Neogit commit" },
  { "<leader>gp", function() require("neogit").open({ "push" }) end, desc = "Git push" },
  { "<leader>gl", function() require("neogit").open({ "pull" }) end, desc = "Git pull" },

  { "<leader>gh", group = "Hunks" },
  { "<leader>ghs", function() require("gitsigns").stage_hunk() end, desc = "Stage hunk" },
  { "<leader>ghr", function() require("gitsigns").reset_hunk() end, desc = "Reset hunk" },
  { "<leader>ghp", function() require("gitsigns").preview_hunk() end, desc = "Preview hunk" },
  { "<leader>ghS", function() require("gitsigns").stage_buffer() end, desc = "Stage buffer" },
  { "<leader>ghu", function() require("gitsigns").undo_stage_hunk() end, desc = "Undo stage hunk" },
  { "<leader>ghd", function() require("gitsigns").diffthis() end, desc = "Diff this" },

  { "<leader>ghs", function() require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, desc = "Stage hunk", mode = "v" },
  { "<leader>ghr", function() require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, desc = "Reset hunk", mode = "v" },

  { "<leader>gb",  function() require("gitsigns").blame_line({ full = true }) end, desc = "Blame line" },
  { "<leader>gbt", function() require("gitsigns").toggle_current_line_blame() end, desc = "Toggle line blame" },

  { "<leader>gt", group = "Toggles (Git)" },
  { "<leader>gtd", function() require("gitsigns").toggle_deleted() end, desc = "Toggle deleted lines" },

  { "]h", function() require("gitsigns").nav_hunk("next") end, desc = "Next hunk" },
  { "[h", function() require("gitsigns").nav_hunk("prev") end, desc = "Previous hunk" },
})
