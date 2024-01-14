-- https://github.com/neovim/nvim-lspconfig
-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  -- Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  -- Wat?
  -- buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<Shift-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<Leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<Leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<Leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  -- This feels less useful than having DocGen
  -- buf_set_keymap('n', '<Leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<Leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<Leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', '<Leader>gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<Leader>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<Leader>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  buf_set_keymap("n", "<Leader>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
end

-- https://github.com/kabouzeid/nvim-lspinstall/tree/ecf58b96dd1d09f8e431427633c63ed964efde48#advanced-configuration-recommended
-- but totally edited to not have npm stuff (if I can avoid it)
-- and clean up that unreadable lua coding style.
-- Populate the function later.
function setup_servers()
  -- python
  local lsputil = require('lspconfig/util')
  local pylsp = vim.api.nvim_eval("substitute(g:python3_host_prog, 'python3$', 'pylsp', 'g')")
  local venv = vim.fn.join({vim.fn.expand('$HOME'), '.virtualenvs', 'nvim-runtime'}, '/')
  local lspconfig = require('lspconfig')

  if vim.fn.executable('ruff-lsp') == 1 then
    lspconfig.ruff_lsp.setup {
      root_dir = function(fname)
        local root_files = {
          'pyproject.toml',
          'setup.py',
          'setup.cfg',
          'requirements.txt',
          'Pipfile',
        }
        return lsputil.root_pattern(unpack(root_files))(fname) or lsputil.find_git_ancestor(fname)
      end,
      on_attach = on_attach,
      init_options = {
        settings = {
          -- Any extra CLI arguments for `ruff` go here.
          args = {
          }
        }
      }
    }
  end

  if vim.fn.executable(pylsp) == 1 then
    lspconfig.pylsp.setup {
      cmd = {pylsp},
      root_dir = function(fname)
        local root_files = {
          'pyproject.toml',
          'setup.py',
          'setup.cfg',
          'requirements.txt',
          'Pipfile',
        }
        return lsputil.root_pattern(unpack(root_files))(fname) or lsputil.find_git_ancestor(fname)
      end,
      settings = {
        pylsp = {
          plugins = {
            pylint = { enabled = false },
            ruff = {
              extendSelect = { "I" },
            },
          },
        },
      },
      cmd_env = {VIRTUAL_ENV = venv, PATH = lsputil.path.join(venv, 'bin') .. ':' .. vim.env.PATH},
      on_attach = on_attach,
    }
  end

  -- rust
  lspconfig.rust_analyzer.setup {
    capabilities = capabilities,
    autoimport = 'enable',
    on_attach = on_attach,
  }

  ---- Doesn't cope with submodule project not having *.csproj files
  -- csharp // `dotnet tool install --global csharp-ls`
  -- local csharp_ls_bin = vim.fn.join({vim.fn.expand('$HOME'), '.dotnet', 'tools', 'csharp-ls'}, '/')
  -- require('lspconfig').csharp_ls.setup {
  --   cmd = { csharp_ls_bin },
  -- }

  -- https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md#omnisharp
  -- XXX: omnisharp_bin should not be hard-coded like so, the symlink should work
  local pid = vim.fn.getpid()
  local omnisharp_bin = vim.fn.join({vim.fn.expand('$HOME'), '.cache', 'omnisharp-vim', 'omnisharp-roslyn', 'OmniSharp.exe'}, '/')
  require('lspconfig').omnisharp.setup({
    cmd = { omnisharp_bin, "-v", "--languageserver" , "--hostPID", tostring(pid) };
    on_attach = on_attach,
    handlers = {
         ["textDocument/publishDiagnostics"] = vim.lsp.with(
           vim.lsp.diagnostic.on_publish_diagnostics, {
             signs = true
           }
         ),
       },
  })
end
