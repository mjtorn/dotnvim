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
    }),
  })

  -- Set up lspconfig.
  setup_servers()
end
