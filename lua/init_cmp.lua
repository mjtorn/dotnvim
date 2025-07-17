function setup_cmp()
  -- nvim-cmp
  local cmp = require('cmp')

  cmp.setup({
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
    }, {
      {
        name = 'buffer',
        option = {
          -- default
          -- keyword_pattern = [[\%(-\?\d\+\%(\.\d\+\)\?\|\h\w*\%([\-.]\w*\)*\)],
          -- almost default, allow word chars after number
          keyword_pattern = [[\%(-\?\d\+\%(\.\d\+\)\?\w*\|\h\w*\%([\-.]\w*\)*\)]],
          -- keyword matches just whatever meh
          -- keyword_pattern = [[\k\+]],
          keyword_length = 3,
        }
      },
    }, {
      -- { name = 'async_path',
      { name = 'path',
        option = { trailing_slash = true }},
    }
    ),
    mapping = cmp.mapping.preset.insert({
      ["<C-k>"] = cmp.mapping.select_prev_item(), -- previous suggestion
      ["<C-j>"] = cmp.mapping.select_next_item(), -- next suggestion
      ["<S-Tab>"] = cmp.mapping.select_prev_item(), -- previous suggestion
      ["<Tab>"] = cmp.mapping.select_next_item(), -- next suggestion
      ["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
      ["<CR>"] = cmp.mapping.confirm({ select = false }),
      -- Control-t is now a pseudotab, <C-Tab> is unreliable and <C-v><Tab> awkward
      ['<C-t>'] = function()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Tab>', true, true, true), 'n', true)
      end,
    }),
  })

  -- Set up lspconfig.
  setup_servers()
end
