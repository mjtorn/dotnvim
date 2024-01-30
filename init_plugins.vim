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

" This seems to be an issue maybe?
" https://github.com/nvim-telescope/telescope.nvim/issues/82
autocmd FileType TelescopePrompt call deoplete#custom#buffer_option('auto_complete', v:false)

"" some deoplete
" https://github.com/Shougo/deoplete.nvim/blob/master/doc/deoplete.txt
let g:deoplete#enable_at_startup = 1

call deoplete#custom#option({'auto_complete_start_length': 0})

" This may only have been documented at
" https://github.com/calviken/vim-gdscript3/issues/1
" and apparently the sources stuff in the issue is not required
call deoplete#custom#var('omni', 'input_patterns', {
      \ 'gdscript3': ['\.|\w+'],
\})

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
:lua setup_servers()
:lua setup_misc()
:lua require('init_treesitter')

