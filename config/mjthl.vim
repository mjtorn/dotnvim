"" Match whitespaces except where typing
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+\%#\@<!$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+\%#\@<!$/
au InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
au InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()

"" Highlight overfows at 80 and 100 on common code
autocmd BufWinEnter *.py call matchadd('ColorColumn', '\%81v', 100)
autocmd BufWinEnter *.py call matchadd('ColorColumn', '\%101v', 100)
autocmd BufWinEnter *.h,*.c,*cpp call matchadd('ColorColumn', '\%81v', 100)
autocmd BufWinEnter *.h,*.c,*cpp call matchadd('ColorColumn', '\%101v', 100)

"" Tabs highlighted as well plz
set lcs=eol:$,tab:⇥\ ,trail:-,nbsp:␣

"" Tree-sitter and sessions do not play nice, deploy the nuclear option
autocmd VimEnter * lua
  \ local parsers = require'nvim-treesitter.parsers'
  \ if parsers.has_parser(vim.bo.filetype) then
  \   require'nvim-treesitter.highlight'.attach(0)
  \   end
