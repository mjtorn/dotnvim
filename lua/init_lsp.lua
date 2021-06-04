-- https://github.com/kabouzeid/nvim-lspinstall/tree/ecf58b96dd1d09f8e431427633c63ed964efde48#advanced-configuration-recommended
-- but totally edited to not have npm stuff (if I can avoid it)
-- and clean up that unreadable lua coding style.
-- Populate the function later.
function setup_servers()
  python3_host_prog = vim.api.nvim_eval('g:python3_host_prog')
  jedilsp = vim.api.nvim_eval("substitute(g:python3_host_prog, 'python3$', 'jedi-language-server', '')")
  require('lspconfig').jedi_language_server.setup({cmd = {jedilsp}})

  require('lsp_signature').on_attach {hint_enable = false}

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

  require('lspconfig').rust_analyzer.setup {
    capabilities = capabilities,
    autoimport = 'enable',
  }

  -- Defaults but with no SQL
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
end
