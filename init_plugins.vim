" NERDTree

let g:nerdtree_tabs_focus_on_files = 1
let g:NERDTreeWinSize = 30

" Mundo on the right, preview on the bottom, help on the top
let g:mundo_right = 1
let g:mundo_preview_bottom = 1
let g:mundo_help = 1

" Fuzzy finder
nnoremap <C-p> :FuzzyOpen<CR>

"" Play around with ack-grep
" https://www.freecodecamp.org/news/how-to-search-project-wide-vim-ripgrep-ack/
let g:ackprg = 'rg --vimgrep --type-not sql --smart-case'
let g:ack_use_cword_for_empty_search = 1
let g:ack_autoclose = 1
nnoremap <Leader>a :Ack!<SPACE>

" Tabs are maybe the coolest for going to definition. Maybe...
nmap <buffer> gd <plug>DeopleteRustGoToDefinitionTab

"" clang?
let g:clang_library_path="/usr/lib/llvm-3.5/lib/"

" ALE
let g:ale_linters = {
      \ 'cpp': ['clang'],
      \ 'cs': ['OmniSharp'],
      \ 'c': ['clang'],
      \ 'python': ['flake8'],
      \ 'rust': ['analyzer']
\ }
let g:ale_python_flake8_executable = $HOME . '/.config/nvim/bundle/python-support/autoload/nvim_py3/bin/flake8'
let g:python_support_python2_require = 0

" Emmet might be a bit trigger happy
let g:user_emmet_install_global = 0
autocmd FileType html,css EmmetInstall

" Verify some basic things are installed when working in Python
let g:venv_reqs = ['jedi', 'flake8', 'isort', 'flake8-isort', 'pyyaml']

" Here's to hipsterism!
:lua require('init_lsp')
:lua setup_servers()

