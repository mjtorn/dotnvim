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
      { name = 'buffer',
        option = { keyword_length = 0 }},
    }, {
      { name = 'async_path',
        option = { trailing_slash = true }},
    }, {
      { name = 'nvim_lsp_signature_help'}
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
  local capabilities = require('cmp_nvim_lsp').default_capabilities()

  -- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
  require('lspconfig')['omnisharp'].setup {
    capabilities = capabilities
  }
  require('lspconfig')['pylsp'].setup {
    capabilities = capabilities
  }
  require('lspconfig')['rust_analyzer'].setup {
    capabilities = capabilities
  }
end
