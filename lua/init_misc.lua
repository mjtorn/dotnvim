function next_location()
    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local items = vim.fn.getloclist(0)
    local idx = 0
    local item_lnum = -1

    if #items == 0 then
      return
    end

    for i, item in ipairs(items) do
        -- vim.cmd(":echom 'item.lnum " .. item.lnum .. " / " .. curr_line .."'")
        if item.lnum > curr_line then
            idx = i
            item_lnum = item.lnum
            break
        end
    end
    -- vim.cmd(":echom 'idx first " .. idx .. "'")
    if idx == 0 then
        idx = 1
    elseif idx == #items and item_lnum == curr_line + 1 then
        idx = 1
    else
        idx = idx + 1
    end
    -- vim.cmd(":echom 'idx " .. idx .. "'")
    vim.cmd("ll " .. idx)
end

vim.api.nvim_set_keymap("n", "gl", ":lua next_location()<CR>", { noremap = true })

function setup_misc()
  -- All this hackery should make magic snippets work.
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = {
      'documentation',
      'detail',
      'additionalTextEdits',
    }
  }

  -- Grep and file-finding, defaults but with no SQL
  require('telescope').setup {
    defaults = {
      vimgrep_arguments = {
        'rg',
        '--color=never',
        '--type-not=sql',
        '--no-heading',
        '--with-filename',
        '--line-number',
        '--column',
        '--smart-case'
      },
      prompt_position = "bottom",
      prompt_prefix = "> ",
      selection_caret = "> ",
      entry_prefix = "  ",
      initial_mode = "insert",
      selection_strategy = "reset",
      sorting_strategy = "descending",
      layout_strategy = "horizontal",
      layout_defaults = {
        horizontal = {
          mirror = false,
        },
        vertical = {
          mirror = false,
        },
      },
      file_sorter =  require'telescope.sorters'.get_fuzzy_file,
      file_ignore_patterns = {},
      generic_sorter =  require'telescope.sorters'.get_generic_fuzzy_sorter,
      shorten_path = true,
      winblend = 0,
      width = 0.75,
      preview_cutoff = 120,
      results_height = 1,
      results_width = 0.8,
      border = {},
      borderchars = { '─', '│', '─', '│', '╭', '╮', '╯', '╰' },
      color_devicons = true,
      use_less = true,
      set_env = { ['COLORTERM'] = 'truecolor' }, -- default = nil,
      file_previewer = require'telescope.previewers'.vim_buffer_cat.new,
      grep_previewer = require'telescope.previewers'.vim_buffer_vimgrep.new,
      qflist_previewer = require'telescope.previewers'.vim_buffer_qflist.new,

      -- Developer configurations: Not meant for general override
      buffer_previewer_maker = require'telescope.previewers'.buffer_previewer_maker
    }
  }
  require('telescope').load_extension('fzy_native')

  -- Configure lsp-signature
  local lsp_signature_cfg = {
    hint_enable = false,
    always_trigger = true,
    toggle_key = '<C-v>',
    selext_signature_key = '<C-Tab>',
    floating_window_above_cur_line = true,
    auto_close_after = 1,

    floating_window_off_x = 5, -- adjust float windows x position.

    floating_window_off_y = function()
      local winline = vim.fn.winline()
      local pumheight = vim.o.pumheight

      -- Top-of-window check: do nothing, keep default
      if winline - 1 < pumheight then
        return 0
      end

      local winheight = vim.api.nvim_win_get_height(0)
      if winheight - winline < pumheight then
        return -pumheight
      end

      return 0
    end,
  }
  require('lsp_signature').setup(lsp_signature_cfg)

  require('neogen').setup {}

end

