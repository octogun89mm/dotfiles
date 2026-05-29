vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    if not vim.treesitter.query.get(args.match, "highlights") then
      return
    end

    local ok = pcall(vim.treesitter.start, args.buf)
    if not ok then
      return
    end
  end,
})
