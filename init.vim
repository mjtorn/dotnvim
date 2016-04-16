" vim: tabstop=2 expandtab autoindent shiftwidth=2 fileencoding=utf-8

runtime bundle/pathogen/autoload/pathogen.vim
call pathogen#infect()

" Needed for coffeescript
filetype plugin indent on

let g:nerdtree_tabs_focus_on_files = 1
let g:NERDTreeWinSize = 30

set modeline

" Do not want surprises from other input devices
set mouse=

" Prefer this in the statusbar, for vmath and echoes to work
set noshowmode

set expandtab
set tabstop=2
set ruler

set noautochdir

set lazyredraw
set laststatus=2

autocmd BufRead /tmp/mutt* :source ~/.vim/config/mail.vim

" So vim-git works etc
let mapleader=","

"" Look at the undo tree
nnoremap <Leader>u :GundoToggle<CR>
let g:gundo_right = 1

set undofile
set undodir=$HOME/.config/nvim/undo
set undolevels=1000
" How many lines
set undoreload=10000

let g:ctrlp_custom_ignore = {
\  'file': '\v\.(pyc|o)$',
\ }

" Make insertlessly do less. Frees the space key for folding
let g:insertlessly_insert_spaces = 0
let g:insertlessly_backspace_past_bol = 0
let g:insertlessly_cleanup_trailing_ws = 0
let g:insertlessly_cleanup_all_ws = 0

"" some deoplete
" https://github.com/Shougo/deoplete.nvim/blob/master/doc/deoplete.txt
let g:deoplete#enable_at_startup = 1
let g:deoplete#sources#jedi#show_docstring = 1

"" clang?
let g:clang_library_path="/usr/lib/llvm-3.5/lib/"

"" Because I used to have a recovery function that did not work and I learned
"" to save my files instead
set nobackup
set noswapfile

"" Try to go full hipster
set relativenumber
let &number = 1

set foldcolumn=1

"" Fix some file presets
autocmd BufEnter *.py setl tabstop=4 expandtab autoindent shiftwidth=4 fileencoding=utf-8 foldmethod=syntax
autocmd BufEnter *ml setl tabstop=4 expandtab autoindent shiftwidth=4 fileencoding=utf-8
autocmd BufEnter *vim setl tabstop=2 expandtab autoindent shiftwidth=2 fileencoding=utf-8
autocmd BufEnter *.coffee setl tabstop=2 expandtab autoindent shiftwidth=2 fileencoding=utf-8 foldmethod=indent
autocmd BufEnter *.c setl tabstop=4 expandtab autoindent shiftwidth=4 fileencoding=utf-8 foldmethod=syntax
autocmd BufEnter *.cpp setl tabstop=4 expandtab autoindent shiftwidth=4 fileencoding=utf-8 foldmethod=syntax
autocmd BufEnter *.java setl tabstop=4 expandtab autoindent shiftwidth=4 fileencoding=utf-8 foldmethod=syntax

"" And not have folds closed by default!
set foldlevelstart=10

"" From neocomplete and http://blog.fluther.com/django-vim/
" XXX: Is markdown really html enough to use the same completions
autocmd FileType python setlocal omnifunc=jedi#completions
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType fbml set omnifunc=htmlcomplete#CompleteTags
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

" Syntastic
let g:syntastic_python_checkers = ['flake8', 'python']

" Emmet might be a bit trigger happy
let g:user_emmet_install_global = 0
autocmd FileType html,css EmmetInstall

" Though this doesn't indent inside the parentheses, I like it
let g:pyindent_open_paren = '&-sw'
let g:pyindent_nested_paren = '&-sw'

"" This sources everything else I want
:source ~/.config/nvim/config/mjt.vim

