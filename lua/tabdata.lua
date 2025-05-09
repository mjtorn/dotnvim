-- vim: ts=2 sts=2 sw=2 et ai

function list_buffers_in_tab(tabnr)
  local tabpage = vim.api.nvim_tabpage_get_win(tabnr)
  local wins = vim.api.nvim_tabpage_list_wins(tabnr)

  for _, win in ipairs(wins) do
    local bufnr = vim.api.nvim_win_get_buf(win)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local modified = vim.api.nvim_buf_get_option(bufnr, "modified")
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    if filename then
      print(string.format("%s (%s, %d lines)", filename, modified and "modified" or "unmodified", line_count))
    else
      print("(no name)")
    end
  end
end

vim.api.nvim_set_keymap("n", "<Leader>Tp", ":lua list_buffers_in_tab(0)<CR>", { noremap = false }) -- 0 is current
