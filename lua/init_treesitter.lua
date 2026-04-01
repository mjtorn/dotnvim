require('nvim-treesitter').setup {
  install_dir = vim.fn.stdpath('data') .. '/site',
  ignore_install = { }, -- List of parsers to ignore installing
  highlight = {
    enable = true,              -- false will disable the whole extension
    disable = { },  -- list of language that will be disabled
    -- additional_vim_regex_highlighting = {"python"},  -- https://www.reddit.com/r/neovim/comments/ok9frp/v05_treesitter_does_anyone_have_python_indent/
    -- additional_vim_regex_highlighting = { "x12", "edifact" },
  },
  incremental_selection = { enable = true },
  textobjects = { enable = true },
  indent = { enable = true },
  fold = { enable = true },
}

vim.treesitter.language.register('x12', {'edifact'})

-- New-style Tree-sitter X12 registration (fill in your repo URL)
vim.api.nvim_create_autocmd("User", { pattern = "TSUpdate",
  callback = function()
    require("nvim-treesitter.parsers").x12 = {
      install_info = {
        url = "https://github.com/hugginsio/tree-sitter-x12.git",
        files = { "src/parser.c" },
        branch = "main",
      },
      pattern = { "edifact", "x12" },
      -- XXX: Does this even do anything? Highlight seems non-functional
      callback = function(args)
        local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype) or "x12"
        pcall(require("nvim-treesitter.highlight").attach, args.buf, lang)
      end,
    }
  end,
})

require('nvim-treesitter').install { "c_sharp", "lua", "python", "rust", "vimdoc", "x12" }
