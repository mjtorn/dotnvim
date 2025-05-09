-- vim: ts=2 sts=2 sw=2 et ai

local tabdata_win = nil;
vim.api.nvim_set_hl(0, "TabDataTitle", { fg = "#ff00ff", bg = "#000000" }) -- Set title highlight

function list_buffers_in_tab(tabnr)
  local tabord = vim.api.nvim_tabpage_get_number(tabnr)
  local wins = vim.api.nvim_tabpage_list_wins(tabnr)

  local lines = {}
  table.insert(lines, 1, string.format("Buffers in Tab %d", tabord)) -- Add title line

  for _, win in ipairs(wins) do
    local bufnr = vim.api.nvim_win_get_buf(win)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local modified = vim.api.nvim_buf_get_option(bufnr, "modified")
    local line_count = vim.api.nvim_buf_line_count(bufnr)

    if filename then
      table.insert(lines, string.format("%s (%s, %d lines)", filename, modified and "modified" or "unmodified", line_count))
    else
      table.insert(lines, "(no name)")
    end
  end

  return lines
end

function validate_winnr(winnr)
  return winnr ~= nil and vim.api.nvim_win_is_valid(winnr)
end

function tabdata()
  local tabnr = vim.api.nvim_get_current_tabpage()  -- This would be an internal nr
  print(tabnr)

  -- These should never really be changed
  local is_listed = false;
  local is_scratch = true;
  local autoenter = true;
  local strict_popup_lines = true;
  local popup_buf_start = 0;
  local popup_buf_end = -1;  -- all the way to the end

  local lines = list_buffers_in_tab(tabnr)
  local bufnr = vim.api.nvim_create_buf(is_listed, is_scratch)

  vim.api.nvim_buf_set_lines(bufnr, popup_buf_start, popup_buf_end, strict_popup_lines, lines)

  tabdata_win = vim.api.nvim_open_win(bufnr, autoenter, {
    relative = "editor",
    width = 60,
    height = 10,
    col = (vim.opt.columns:get() - 60) / 2,
    row = (vim.opt.lines:get() - 10) / 2,
    style = "minimal",
    border = "rounded",
    focusable = false,
  })

  vim.api.nvim_win_set_option(tabdata_win, "winhl", "Normal:Normal") -- Reset highlight for normal lines
  vim.api.nvim_buf_add_highlight(bufnr, -1, "TabDataTitle", 0, 0, -1) -- Highlight title line

  -- A temporary autocmd which will close the popup when moving out
  autocmd_id = vim.api.nvim_create_autocmd("CursorMoved", {
    pattern = "*",
    callback = function()
      if validate_winnr(tabdata_win) then
          local force_close = true
          local cursor_win = vim.api.nvim_get_current_win()

          -- Did we jump out of the popup?
          if cursor_win ~= tabdata_win then
            vim.api.nvim_win_close(tabdata_win, force_close)
            tabdata_win = nil

            -- We don't wanna trigger this more than we gotta
            vim.api.nvim_del_autocmd(autocmd_id)
            autocmd_id = nil
          end
        end
    end,
  })
end

vim.api.nvim_set_keymap("n", "<Leader>Tp", ":lua tabdata()<CR>", { noremap = false }) -- 0 is current
