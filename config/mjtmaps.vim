"" Window navigation to be a bit easier
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

"" Kinesis arrows starting to cause me grief
inoremap <C-h>   <Left>
inoremap <C-j>   <Down>
inoremap <C-k>   <Up>
inoremap <C-l>   <Right>
vnoremap <C-h>   <Left>
vnoremap <C-j>   <Down>
vnoremap <C-k>   <Up>
vnoremap <C-l>   <Right>

" FIXME: The C-i key in insert mode should pref. not be a backspace :D
imap <Up>    <NOP>
imap <Down>  <NOP>
imap <Left>  <NOP>
imap <Right> <NOP>
vmap <Up>    <NOP>
vmap <Down>  <NOP>
vmap <Left>  <NOP>
vmap <Right> <NOP>

map <Up>    <NOP>
map <Down>  <NOP>
map <Left>  <NOP>
map <Right> <NOP>

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

"" Ack like Mars Attacks
let g:ackprg = 'rg --vimgrep --type-not sql --smart-case'
nmap <Leader>A :Ack<Space>

"" Navigate into wrapped lines as if they were real lines, but skip over them
"" like expected
nnoremap <expr> j v:count ? 'j' : 'gj'
nnoremap <expr> k v:count ? 'k' : 'gk'

"" Quickfix navigation
" .fi style! Would probably not work as [q and ]q with other keymaps
nnoremap <silent> öq :cprevious<CR>
nnoremap <silent> äq :cnext<CR>

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

"" Copy line and edit
nmap <Leader>c yyPVgcj

nmap ;C :source ~/.config/nvim/nvimrc<Enter>
nmap ;S :source ~/.config/nvim/plugin/scratchpad.vim<Enter>
nmap ;M :source ~/.config/nvim/config/mjt.vim<Enter>

" Stolen from mbrochh's vim-as-a-python-ide talk
" and why not map it to tab because that's easier on the hand
vnoremap <Tab> >gv " better indentation
vnoremap <S-Tab> <gv " better indentation
nnoremap <Tab> >gv " better indentation
nnoremap <S-Tab> <gv " better indentation
" also get rid of the reflex to use > and <
vmap > <NOP>
vmap < <NOP>
" FIXME: This seems to fail :/
" nmap > <NOP>
" nmap < <NOP>

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

"" neogen
nmap <Leader>d :lua require('neogen').generate()<CR>
nmap <Leader>D :lua require('neogen').generate({ type = 'class' })<CR>
nmap <Leader>x :lua require('neogen').generate({ type = 'type' })<CR>
nmap <Leader>X :lua require('neogen').generate({ type = 'file' })<CR>

"" That floater-killer
nmap <Esc> :call CloseFloats()<CR>
