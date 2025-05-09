-- vim: ts=2 sts=2 sw=2 et ai

-- Some TabNavTitle highlight configuration is nice to have in the conf

local tabdata_win = nil;

function validate_winnr(winnr)
  return winnr ~= nil and vim.api.nvim_win_is_valid(winnr)
end

function max_length(lines)
  local max_length = 0

  for _, line in ipairs(lines) do
    max_length = math.max(max_length, #line)
  end

  return max_length
end

local function get_tab_mapping()
  local tab_mapping = {}
  local tab_pages = vim.api.nvim_list_tabpages()

  for i, tab_page in ipairs(tab_pages) do
    local tab_number = vim.api.nvim_tabpage_get_number(tab_page)
    tab_mapping[tab_number] = tab_page
  end

  -- print(vim.inspect(tab_mapping))
  return tab_mapping
end

function open_prev(tabnr)
  local mapping = get_tab_mapping()

  -- The internal number must become something manageable
  local tabord = vim.api.nvim_tabpage_get_number(tabnr)
  local prevord = tabord - 1

  if prevord == 0 then
    prevord = #mapping
  end

  -- vim.cmd(":tabprev")
  vim.api.nvim_win_close(tabdata_win, force_close)
  tabdata_win = nil
  tabdata(mapping[prevord])
end

function open_next(tabnr)
  local mapping = get_tab_mapping()

  -- The internal number must become something manageable
  local tabord = vim.api.nvim_tabpage_get_number(tabnr)
  local nextord = tabord + 1

  if nextord == #mapping + 1 then
    nextord = 1
  end

  -- vim.cmd(":tabnext")
  vim.api.nvim_win_close(tabdata_win, force_close)
  tabdata_win = nil
  tabdata(mapping[nextord])
end

function go(tabnr)
  local mapping = get_tab_mapping()

  -- The internal number must become something manageable
  local tabord = vim.api.nvim_tabpage_get_number(tabnr)

  vim.api.nvim_win_close(tabdata_win, force_close)
  tabdata_win = nil
  vim.cmd(":tabnext " .. tabord)
end

local function list_buffers_in_tab(tabnr)
  local tabord = vim.api.nvim_tabpage_get_number(tabnr)
  local wins = vim.api.nvim_tabpage_list_wins(tabnr)

  local lines = {}
  table.insert(lines, string.format("Buffers in tab %d", tabord)) -- Add title line
  table.insert(lines, " ")  -- Newlines not welcome

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

function tabdata(tabnr)
  -- This would be an internal nr
  -- print(tabnr)

  -- These should never really be changed
  local is_listed = false;
  local is_scratch = true;
  local autoenter = true;
  local strict_popup_lines = true;
  local popup_buf_start = 0;
  local popup_buf_end = -1;  -- all the way to the end

  -- Ensure cleanliness

  if validate_winnr(tabdata_win) then
    vim.api.nvim_win_close(tabdata_win, force_close)
    tabdata_win = nil
  end

  -- Get to it
  local lines = list_buffers_in_tab(tabnr)
  local bufnr = vim.api.nvim_create_buf(is_listed, is_scratch)

  vim.api.nvim_buf_set_lines(bufnr, popup_buf_start, popup_buf_end, strict_popup_lines, lines)

  local width = max_length(lines)
  tabdata_win = vim.api.nvim_open_win(bufnr, autoenter, {
    relative = "editor",
    width = width,
    height = #lines,
    col = (vim.opt.columns:get() - width) / 2,
    row = 1,
    style = "minimal",
    border = "rounded",
    focusable = false,
  })

  vim.api.nvim_win_set_option(tabdata_win, "winhl", "Normal:Normal") -- Reset highlight for normal lines
  vim.api.nvim_buf_add_highlight(bufnr, -1, "TabNavTitle", 0, 0, -1) -- Highlight title line

  vim.api.nvim_buf_set_keymap(bufnr, "n", "<", ":lua open_prev(" .. tabnr .. ")<CR>", { noremap = false })
  vim.api.nvim_buf_set_keymap(bufnr, "n", ">", ":lua open_next(".. tabnr .. ")<CR>", { noremap = false })
  vim.api.nvim_buf_set_keymap(bufnr, "n", "G", ":lua go(" .. tabnr .. ")<CR>", { noremap = false })

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

vim.api.nvim_set_keymap("n", "<Leader>tn", ":lua tabdata(vim.api.nvim_get_current_tabpage())<CR>", { noremap = false }) -- 0 is current
