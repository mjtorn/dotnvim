"" Window navigation to be a bit easier
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

"" Double <Leader> is a good way to prevent fiddling with timeoutlen!
inoremap <Leader><Leader> <Leader>

"" Look at the undo tree
nnoremap <Leader>u :MundoToggle<CR>

"" To get NERDTree going
nmap <Leader>N :NERDTreeTabsToggle<CR>

"" Add ability to quickly toggle MBE
"" XXX: This does suck because it skips to the last tab, but MBE isn't
""      super-crucial to always have open
let g:miniBufExplorerAutoStart = 0
nmap <Leader>m :MBEToggleAll<CR>

"" Navigate into wrapped lines as if they were real lines, but skip over them
"" like expected
nnoremap <expr> j v:count ? 'j' : 'gj'
nnoremap <expr> k v:count ? 'k' : 'gk'

"" Also prefer Y to be congruent with C and D
nnoremap Y y$

"" Nicer buffer scroll
nnoremap <C-E> <C-E>j
nnoremap <C-Y> <C-Y>k

imap <C-E> <ESC><C-E>i
imap <C-Y> <ESC><C-Y>i

"" Folding space like the spice
map <Space> za

"" Would appreciate Control-Enter behaving as without insert mode
"imap <C-CR> <ESC><CR>i

"" Play around with ack-grep
let g:ackprg="ack -H --nocolor --nogroup --column"
nnoremap <Leader>a :Ack

"" Copy line and edit
nmap <Leader>c yyPVgcj

nmap ;C :source ~/.config/nvim/nvimrc<Enter>
nmap ;S :source ~/.config/nvim/plugin/scratchpad.vim<Enter>
nmap ;M :source ~/.config/nvim/config/mjt.vim<Enter>

" Stolen from mbrochh's vim-as-a-python-ide talk
vnoremap < <gv " better indentation
vnoremap > >gv " better indentation

" Damian Conway's dragvisual
vmap  <expr>  H   DVB_Drag('left')
vmap  <expr>  L   DVB_Drag('right')
vmap  <expr>  J   DVB_Drag('down')
vmap  <expr>  K   DVB_Drag('up')
vmap  <expr>  P   DVB_Duplicate()

" Damian Conway's vmath
vmap  <expr>  ++  VMATH_YankAndAnalyse()
nmap          ++  vip++

"" Fix whitespaces manually
nnoremap <Leader>fw :%s/\s\+\%#\@<!$//g<CR>

"" When searching in visual mode, constrain to visual
vnoremap / <Esc>/\%V

"" Highlighted search clear
nnoremap <Leader>h :noh<CR>

"" Old git.vim mappings haphazardly thrown at vim-fugitive
nnoremap <Leader>gs :G<Enter>
nnoremap <Leader>ga :Git add %<Enter>
nnoremap <Leader>gc :Git commit %<Enter>
nnoremap <Leader>gb :Git blame<Enter>
nnoremap <Leader>gD :Git diff --staged %<Enter>
nnoremap <Leader>gd :Gdiffsplit<Enter>
nnoremap <Leader>gl :Git log %<Enter>
nnoremap <Leader>gL :Gclog<Enter>  " XXX Nice if this didn't destroy the original buffer, use with care
" XXX At least these exhibit issues if tmux is vertically split
nnoremap <Leader>gP :Git push --force-with-lease<Enter>
nnoremap <Leader>gp :Git pull<Enter>

"" Escoria debug
autocmd FileType escoria nnoremap <Leader>ed i<CR># {{{ DEBUG<CR><CR># }}}<CR><ESC>A<CR><ESC>3k

"" Debug current highlight
map <F9> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
  \ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
  \ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>

