-- https://github.com/kabouzeid/nvim-lspinstall/tree/ecf58b96dd1d09f8e431427633c63ed964efde48#advanced-configuration-recommended
-- but totally edited to not have npm stuff (if I can avoid it)
-- and clean up that unreadable lua coding style.
-- Populate the function later.
function setup_servers()
  python3_host_prog = vim.api.nvim_eval('g:python3_host_prog')
  jedilsp = vim.api.nvim_eval("substitute(g:python3_host_prog, 'python3$', 'jedi-language-server', '')")
  require('lspconfig').jedi_language_server.setup({cmd = {jedilsp}})

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
end
