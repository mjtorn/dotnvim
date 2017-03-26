" NERDTree

let g:nerdtree_tabs_focus_on_files = 1
let g:NERDTreeWinSize = 30

" Gundo on the right
let g:gundo_right = 1

" Ctrlp should ignore pyc files
let g:ctrlp_custom_ignore = {
\  'file': '\v\.(pyc|o)$',
\ }

"" some deoplete
" https://github.com/Shougo/deoplete.nvim/blob/master/doc/deoplete.txt
let g:deoplete#enable_at_startup = 1
let g:deoplete#auto_complete_start_length = 0
let g:deoplete#sources#jedi#show_docstring = 1
let g:jedi#completions_enabled = 0
let g:jedi#auto_vim_configuration = 0
let g:jedi#smart_auto_mappings = 0
let g:jedi#show_call_signatures = 1

"" clang?
let g:clang_library_path="/usr/lib/llvm-3.5/lib/"

" ALE
let g:ale_linters = {
      \ 'cpp': ['clang'],
      \ 'c': ['clang'],
      \ 'python': ['flake8']
\ }
let g:ale_python_flake8_executable = $HOME . '/.config/nvim/bundle/python-support/autoload/nvim_py3/bin/flake8'
let g:python_support_python2_require = 0

" Emmet might be a bit trigger happy
let g:user_emmet_install_global = 0
autocmd FileType html,css EmmetInstall

" Verify some basic things are installed when working in Python
let g:venv_reqs = ['jedi', 'flake8', 'isort', 'flake8-isort', 'pyyaml']

