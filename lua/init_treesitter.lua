require('nvim-treesitter.configs').setup {
  ensure_installed = "maintained", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  ignore_install = { }, -- List of parsers to ignore installing
  highlight = {
    enable = true,              -- false will disable the whole extension
    disable = { },  -- list of language that will be disabled
  },
  incremental_selection = { enable = true },
  textobjects = { enable = true },
  indent = { enable = true },
}

require('nvim-treesitter.configs').setup {
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
