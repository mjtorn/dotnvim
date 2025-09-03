require('nvim-treesitter.configs').setup {
  ensure_installed = { "c_sharp", "lua", "python", "rust", "vimdoc", "x12" },
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
  refactor = {
    highlight_definitions = { enable = false },
    highlight_current_scope = { enable = false },
    smart_rename = {
      enable = true,
      disable = { "c_sharp" },
      keymaps = {
        smart_rename = "grr",
      },
      navigation = {
        enable = true,
        keymaps = {
          goto_definition = "gnd",
          list_definitions = "gnD",
          list_definitions_toc = "gO",
          goto_next_usage = "<a-*>",
          goto_previous_usage = "<a-#>",
        },
      },
    },
  },
}

local parser_config = require "nvim-treesitter.parsers".get_parser_configs()

-- Optional Tree-sitter X12 registration (fill in your repo URL)
-- local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.x12 = {
  install_info = {
    url = "https://github.com/hugginsio/tree-sitter-x12.git",
    files = { "src/parser.c" },
    branch = "main",
    -- or 'generate_from_grammar = true' if using a grammar.js
  },
  filetype = "x12",
}

vim.treesitter.language.register('x12', 'edifact')

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "edifact", "x12" },
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype) or "x12"
    pcall(require("nvim-treesitter.highlight").attach, args.buf, lang)
  end,
})

