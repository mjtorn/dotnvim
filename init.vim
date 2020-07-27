" vim: tabstop=2 expandtab autoindent shiftwidth=2 fileencoding=utf-8

" Set this before Pathogen just to be safe
let g:python3_host_prog = $HOME . '/.config/nvim/bundle/python-support/autoload/nvim_py3/bin/python3'

runtime bundle/pathogen/autoload/pathogen.vim
call pathogen#infect()

""
" Define a function for loading local configs, call it later in this file
func! LoadLocalConf()
  if !exists('g:local_conf_loaded')
    let s:path = getcwd() . '/.local.vim'
    if findfile(s:path) == s:path
      exec 'source ' . s:path
      let g:local_conf_loaded = 1
    endif
    for s:path in [getcwd() . '/.javacomplete.vim', getcwd() . '/.syntastic_conf.vim', getcwd() . '/.ctrlp_conf.vim']
      if findfile(s:path) == s:path
        echom 'You should move this to .local.vim: ' . s:path
      endif
    endfor
  endif
endfunc

" So vim-git works etc
let mapleader=","

" Though this doesn't indent inside the parentheses, I like it
let g:pyindent_open_paren = '&-sw'
let g:pyindent_nested_paren = '&-sw'

" Needed for coffeescript
filetype plugin indent on

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

set undofile
set undodir=$HOME/.config/nvim/undo
set undolevels=1000
" How many lines
set undoreload=10000

"" Because I used to have a recovery function that did not work and I learned
"" to save my files instead
set nobackup
set noswapfile

"" And not have folds closed by default!
set foldlevelstart=10

"" Rust needs speshul config
let g:rust_fold = 1

"" And rust.vim's autoformat
let g:rustfmt_autosave = 0

"" Try to go full hipster
set relativenumber
let &number = 1

set foldcolumn=1

"" Fix some file presets
autocmd BufRead /tmp/mutt* :source ~/.vim/config/mail.vim
autocmd BufEnter *.py setl tabstop=4 expandtab autoindent shiftwidth=4 fileencoding=utf-8 foldmethod=syntax
autocmd BufEnter *ml setl tabstop=4 expandtab autoindent shiftwidth=4 fileencoding=utf-8
autocmd BufEnter *vim setl tabstop=2 expandtab autoindent shiftwidth=2 fileencoding=utf-8
autocmd BufEnter *.coffee setl tabstop=2 expandtab autoindent shiftwidth=2 fileencoding=utf-8 foldmethod=indent
autocmd BufEnter *.c setl tabstop=4 expandtab autoindent shiftwidth=4 fileencoding=utf-8 foldmethod=syntax
autocmd BufEnter *.cpp setl tabstop=4 expandtab autoindent shiftwidth=4 fileencoding=utf-8 foldmethod=syntax
autocmd BufEnter *.java setl tabstop=4 expandtab autoindent shiftwidth=4 fileencoding=utf-8 foldmethod=syntax

"" From neocomplete and http://blog.fluther.com/django-vim/
" XXX: Is markdown really html enough to use the same completions
autocmd FileType python setlocal omnifunc=jedi#completions
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType fbml set omnifunc=htmlcomplete#CompleteTags
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

autocmd FileType gdscript3 setl tabstop=4 noexpandtab autoindent shiftwidth=4 fileencoding=utf-8 foldmethod=syntax
autocmd FileType escoria setl tabstop=4 noexpandtab autoindent shiftwidth=4 fileencoding=utf-8
" To work with commentary.vim
autocmd FileType escoria setl commentstring=#\ %s

"" Update buffers if files are changed
autocmd CursorHold,CursorHoldI,FocusGained,BufEnter * checktime
autocmd FileChangedShellPost *
  \ echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None

" My defaults for plugins
:source ~/.config/nvim/init_plugins.vim

" Local configurations
call LoadLocalConf()

" Interface with python-support.nvim
let g:python_support_python3_requirements = extend(get(g:, 'python_support_python3_requirements', []), g:venv_reqs)

"" This sources everything else I want
:source ~/.config/nvim/config/mjt.vim

