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
  -- vim.cmd("echo 'setting up servers'")
  local pid = vim.fn.getpid()

  local capabilities = require('cmp_nvim_lsp').default_capabilities()

  vim.diagnostic.config({
    -- Use the default configuration
    virtual_lines = false

    -- Alternatively, customize specific options
    -- virtual_lines = {
    --   -- Only show virtual line diagnostics for the current cursor line
    --   current_line = true
    -- }
  })

  -- This is slow
  -- vim.api.nvim_create_autocmd("CursorHold", {
  --   callback = function()
  --     vim.diagnostic.open_float(nil, {
  --       focusable = false,
  --       scope = "line",  -- only show for the current line
  --       close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
  --     })
  --   end,
  -- })

  do
    local grp = vim.api.nvim_create_augroup("LiveDiagnosticHover", { clear = true })
    local last = { buf = nil, lnum = -1, col = -1 }

    local function open_float_at_cursor()
      -- Avoid reopening if we didn't actually move
      local buf = vim.api.nvim_get_current_buf()
      local pos = vim.api.nvim_win_get_cursor(0) -- {lnum, col}, 1-based lnum
      if last.buf == buf and last.lnum == pos[1] and last.col == pos[2] then
        return
      end
      last = { buf = buf, lnum = pos[1], col = pos[2] }

      local opts = {
        focusable = false,
        close_events = { "CursorMoved", "CursorMovedI", "BufHidden", "InsertLeave", "WinScrolled" },
        border = "rounded",
        source = "if_many",
        severity_sort = true,
      }

      -- Prefer showing diagnostics exactly at cursor (Neovim ≥ 0.10),
      -- fall back to the whole line on older versions.
      local ok, float_buf, winid = pcall(vim.diagnostic.open_float, nil, vim.tbl_extend("force", opts, { scope = "cursor" }))
      if not ok then
        pcall(vim.diagnostic.open_float, nil, vim.tbl_extend("force", opts, { scope = "line" }))
      elseif winid and vim.api.nvim_win_is_valid(winid) then
        vim.api.nvim_win_set_option(winid, "winhl", "FloatBorder:Red")
      end
    end

    -- Fire on movement in normal/insert mode
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      group = grp,
      callback = function()
        -- Tiny debounce to reduce flicker when you hold the arrow key
        vim.defer_fn(open_float_at_cursor, 10)
      end,
    })
  end

  -- Adapted from
  -- https://gist.github.com/crwebb85/fda79b17a7df8517d5ae0a1cc7722611
  vim.api.nvim_create_user_command('QFLspDiagnostics', function(args)
      if args.args == 'ERROR' then
          vim.diagnostic.setqflist({ severity = vim.diagnostic.severity.ERROR, open = false })
      elseif args.args == 'WARN' then
          vim.diagnostic.setqflist({ severity = vim.diagnostic.severity.WARN, open = false })
      elseif args.args == 'HINT' then
          vim.diagnostic.setqflist({ severity = vim.diagnostic.severity.HINT, open = false })
      elseif args.args == 'INFO' then
          vim.diagnostic.setqflist({ severity = vim.diagnostic.severity.INFO, open = false })
      else
          vim.diagnostic.setqflist({ open = false })
      end
  end, {
      desc = 'Adds lsp diagnostic to the Quickfix list',
      complete = function() return { 'ERROR', 'WARN', 'HINT', 'INFO' } end,
      nargs = '?',
  })

  vim.api.nvim_create_user_command('LocLspDiagnostics', function(args)
      if args.args == 'ERROR' then
          vim.diagnostic.setloclist({ severity = vim.diagnostic.severity.ERROR, open = false })
      elseif args.args == 'WARN' then
          vim.diagnostic.setloclist({ severity = vim.diagnostic.severity.WARN, open = false })
      elseif args.args == 'HINT' then
          vim.diagnostic.setloclist({ severity = vim.diagnostic.severity.HINT, open = false })
      elseif args.args == 'INFO' then
          vim.diagnostic.setloclist({ severity = vim.diagnostic.severity.INFO, open = false })
      else
          vim.diagnostic.setloclist({ open = false })
      end

  end, {
      desc = 'Adds lsp diagnostic to the Location list',
      complete = function() return { 'ERROR', 'WARN', 'HINT', 'INFO' } end,
      nargs = '?',
  })

  vim.api.nvim_create_autocmd({"BufEnter", "DiagnosticChanged"}, {
    pattern = "*",
    callback = function()
      vim.cmd("LocLspDiagnostics")
    end
  })

  -- FIXME I think a handler might make more sense but cba wrt time now
  -- vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  --   vim.lsp.diagnostic.on_publish_diagnostics,
  --   {},
  --   function(err, result, ctx, config)
  --     vim.cmd("echo 'lol'")
  --     vim.cmd("LocLspDiagnostics")
  --   end
  -- )

  -- python
  local pylsp = vim.api.nvim_eval("substitute(g:python3_host_prog, 'python3$', 'pylsp', 'g')")
  local venv
  if vim.env.VIRTUAL_ENV then
    venv = vim.env.VIRTUAL_ENV
  else
    venv = vim.fn.join({vim.fn.expand('$HOME'), '.virtualenvs', 'nvim-runtime'}, '/')
  end

  -- csharp // `dotnet tool install --global csharp-ls`
  local csharp_ls_bin = vim.fn.join({vim.fn.expand('$HOME'), '.dotnet', 'tools', 'csharp-ls'}, '/')

  -- "~/.local/bash-lsp/$ npm init -y", `npm install bash-language-server`, symlinked from `.bin/` to `~/.local/bin/`
  local bash_lsp_bin = vim.fn.join({vim.fn.expand('$HOME'), '.local', 'bin', 'bash-language-server'}, '/')

  if vim.fn.executable('ruff-lsp') == 1 then
    vim.lsp.config("ruff-lsp", {
      root_markers = {
        'pyproject.toml',
        'setup.py',
        'setup.cfg',
        'requirements.txt',
        'Pipfile',
      },
      on_attach = on_attach,
      init_options = {
        settings = {
          -- Any extra CLI arguments for `ruff` go here.
          args = {
          }
        }
      }
    })
    vim.lsp.enable("rust_lsp")
    -- vim.cmd("echo 'set up rust_lsp'")
  end

  if vim.fn.executable(pylsp) == 1 then
    vim.lsp.config(pylsp, {
      filetypes = { 'python' },
      cmd = {pylsp},
      root_markers = {
        'pyproject.toml',
        'setup.py',
        'setup.cfg',
        'requirements.txt',
        'Pipfile',
      },
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
      on_attach = on_attach,
    })
    vim.lsp.enable(pylsp)
    -- vim.cmd("echo 'set up pylsp'")
  end

  -- rust
  if vim.fn.executable("rust-analyzer") == 1 then
    vim.lsp.config("rust_analyzer", {
      filetypes = { 'rust' },
      capabilities = capabilities,
      autoimport = 'enable',
      on_attach = on_attach,
    })
    vim.lsp.enable("rust_analyzer")
    -- vim.cmd("echo 'set up rust_analyzer'")
  end

  ---- Doesn't cope with submodule project not having *.csproj files
  if vim.fn.executable(csharp_ls_bin) == 1 then
    vim.lsp.config("csharp_ls", {
      cmd = { csharp_ls_bin },
      filetypes = { 'cs' },
      on_attach = on_attach,
    })
    vim.lsp.enable("csharp_ls")
    -- vim.cmd("echo 'set up csharp-ls'")
  end

  -- Damn I hate this being node
  if vim.fn.executable(bash_lsp_bin) == 1 then
    vim.lsp.config("bashls", {
      cmd = { bash_lsp_bin, 'start' },
      filetypes = { 'bash', 'sh', 'zsh' },
      on_attach = on_attach,
    })
    vim.lsp.enable("bashls")
    -- vim.cmd("echo 'set up bashls'")
  end

end
