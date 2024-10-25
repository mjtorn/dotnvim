" NERDTree

let g:nerdtree_tabs_focus_on_files = 1
let g:NERDTreeWinSize = 30

" Mundo on the right, preview on the bottom, help on the top
let g:mundo_right = 1
let g:mundo_preview_bottom = 1
let g:mundo_help = 1

" Fuzzy finder
nnoremap <C-p> <CMD>Telescope find_files<CR>

" Grepper
nnoremap <Leader>a <CMD>Telescope live_grep<CR>

" Tabs are maybe the coolest for going to definition. Maybe...
nmap <buffer> gd <plug>DeopleteRustGoToDefinitionTab

" Emmet might be a bit trigger happy
let g:user_emmet_install_global = 0
autocmd FileType html,css EmmetInstall

" treesitter
set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()

" Here's to hipsterism!
:lua require('init_lsp')
:lua require('init_misc')
:lua require('init_cmp')
:lua setup_misc()
:lua require('init_treesitter')
:source ~/.config/nvim/config/omnisharp.vim
:lua setup_cmp()
