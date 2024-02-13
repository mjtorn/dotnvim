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
  local pid = vim.fn.getpid()
  local lspconfig = require('lspconfig')
  local lsputil = require('lspconfig/util')

  local capabilities = require('cmp_nvim_lsp').default_capabilities()

  -- python
  local pylsp = vim.api.nvim_eval("substitute(g:python3_host_prog, 'python3$', 'pylsp', 'g')")
  local venv = vim.fn.join({vim.fn.expand('$HOME'), '.virtualenvs', 'nvim-runtime'}, '/')

  -- csharp // `dotnet tool install --global csharp-ls`
  local csharp_ls_bin = vim.fn.join({vim.fn.expand('$HOME'), '.dotnet', 'tools', 'csharp-ls'}, '/')
  -- XXX: but using that `--languageserver` approach just fails autocompletes and docs
  local omnisharp_bin = vim.fn.join({vim.fn.expand('$HOME'), '.cache', 'omnisharp-vim', 'omnisharp-roslyn', 'OmniSharp.exe'}, '/')

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
  lspconfig.csharp_ls.setup {
    cmd = { csharp_ls_bin },
    on_attach = on_attach,
  }

  lspconfig.omnisharp.setup {
    -- cmd = { '/bin/mono', omnisharp_bin, '--languageserver' , '--hostPID', tostring(pid) },
    -- cmd = { "dotnet", "/home/mjt/.cache/omnisharp-vim/omnisharp-roslyn/OmniSharp.dll" },

    cmd = { omnisharp_bin, '--languageserver', '--hostPID', tostring(pid) };

    -- https://github.com/Hoffs/omnisharp-extended-lsp.nvim
    handlers = {
      ["textDocument/definition"] = require('omnisharp_extended').handler,
    },

    -- Enables support for reading code style, naming convention and analyzer
    -- settings from .editorconfig.
    enable_editorconfig_support = true,

    -- If true, MSBuild project system will only load projects for files that
    -- were opened in the editor. This setting is useful for big C# codebases
    -- and allows for faster initialization of code navigation features only
    -- for projects that are relevant to code that is being edited. With this
    -- setting enabled OmniSharp may load fewer projects and may thus display
    -- incomplete reference lists for symbols.
    -- enable_ms_build_load_projects_on_demand = true,
    enable_ms_build_load_projects_on_demand = false,

    -- Enables support for roslyn analyzers, code fixes and rulesets.
    enable_roslyn_analyzers = false,

    -- Specifies whether 'using' directives should be grouped and sorted during
    -- document formatting.
    organize_imports_on_format = false,

    -- Enables support for showing unimported types and unimported extension
    -- methods in completion lists. When committed, the appropriate using
    -- directive will be added at the top of the current file. This option can
    -- have a negative impact on initial completion responsiveness,
    -- particularly for the first few completion sessions after opening a
    -- solution.
    enable_import_completion = false,

    -- Specifies whether to include preview versions of the .NET SDK when
    -- determining which version to use for project loading.
    sdk_include_prereleases = false,

    -- Only run analyzers against open files when 'enableRoslynAnalyzers' is
    -- true
    analyze_open_documents_only = false,

    on_attach = on_attach,
  }
end
