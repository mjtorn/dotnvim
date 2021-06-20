" vim: tabstop=2 shiftwidth=2

"""
""" http://www.tutorialhero.com/click-59484-scripting_the_vim_editor_with_vmscript.php
"""

function! ToggleSyntax()
  if exists("g:syntax_on")
    syntax off
  else
    syntax enable
  endif
endfunction

nmap <Leader>s :call ToggleSyntax()<Enter>

function! CapitalizeCenterAndMoveDown()
  s/\<./\u&/g
  center
  +1
endfunction

"" Meant to show how & is for accessing pseudovariables, like & for vim option, &l for local etc
nmap ]> :let &tabstop += 1<CR>:echo "tabstop:"&tabstop<CR>
nmap [< :let &tabstop -= (&tabstop > 1 ? 1 : 0)<CR>:echo "tabstop:"&tabstop<CR>

function! TogglePaste()
  if exists("g:pasting") && g:pasting == 1
    :set nopaste
    let g:pasting = 0
    echo "nopaste"
  else
    :set paste
    let g:pasting = 1
    echo "paste"
  endif
endfunction

nmap <Leader>p :call TogglePaste()<Enter>

"" http://stackoverflow.com/questions/114431/fast-word-count-function-in-vim/
" Modified to work with empty buffers
function! WordCount()
  if &modified || !exists("b:wordcount")
    let l:old_position = getpos('.')
    let l:old_status = v:statusmsg
    execute "silent normal g\<c-g>"
    if v:statusmsg == "--No lines in buffer--"
      let b:wordcount = 0
    else
      let b:wordcount = str2nr(split(v:statusmsg)[11])
      let v:statusmsg = l:old_status
    endif
    call setpos('.', l:old_position)
    return b:wordcount
  else
    return b:wordcount
  endif
endfunction

nmap \w :echo WordCount()<Enter>

"" http://got-ravings.blogspot.fi/2008/08/vim-pr0n-making-statuslines-that-own.html
" slightly modified
function! FileSize()
  let bytes = getfsize(expand("%:p"))
  if bytes <= 0
       return 0
  endif
  if bytes < 1024
    return bytes
  else
    let rem = bytes % 1024
    if rem == 0
      return (bytes / 1024) . "K"
    else
      return (bytes / 1024) . "K+" . rem
    endif
  endif
endfunction

nmap \S :echo FileSize()<Enter>

" the "saved" text doesn't get a lot of screen time ;)
imap <Leader>s <ESC>:w<CR>:echo "saved"<CR>a

function! ToggleNumbers()
  if &number == 0 && &relativenumber == 0
    let &relativenumber = 1
    let &number = 1
  elseif &number == 1 && &relativenumber == 0
    let &number = 0
  elseif &number == 1 && &relativenumber == 1
    let &number = 1
    let &relativenumber = 0
  endif
endfunction

nmap <Leader>n :call ToggleNumbers()<Enter>

function! ToggleALEColumn()
  if g:ale_sign_column_always == 0
    let g:ale_sign_column_always = 1
    echo "Always showing ALE column"
  else
    let g:ale_sign_column_always = 0
    echo "Not always showing ALE column"
  endif
endfunction

nmap <silent> <Leader>A :call ToggleALEColumn()<Enter>:e<Enter>

" https://github.com/mbrochh/vim-as-a-python-ide/blob/master/.vimrc

set completeopt=longest,menuone
function! OmniPopup(action)
  if pumvisible()
    if a:action == 'j'
      return "\<C-N>"
    elseif a:action == 'k'
      return "\<C-P>"
    endif
  endif
  return a:action
endfunction

inoremap <silent><C-j> <C-R>=OmniPopup('j')<CR>
inoremap <silent><C-k> <C-R>=OmniPopup('k')<CR>

function! FakeMode()
  if exists("g:pasting") && g:pasting == 1
    let paste = '[P] '
  else
    let paste = ''
  endif
  let mode = mode()
  if mode == 'n'
    let mode = 'NORMAL'
  elseif mode == 'v'
    let mode = 'VISUAL'
  elseif mode == 'V'
    let mode = 'VISUAL LINE'
  elseif mode == 'i'
    let mode = 'INSERT'
  elseif mode == 'R'
    let mode = 'REPLACE'
  elseif mode == '^V'
    let mode = 'VISUAL BLOCK'
  else
    let mode = '?? ' . mode
  endif
  return "-- " . paste . mode . " --""
endfunction

function! StripWhiteSpaces()
  :silent! %s/^\s\+$//g
  :silent! %s/^\(\s*[^\s]\+\)\s\+$/\1/g
endfunction
au BufEnter * call StripWhiteSpaces()

function! MaybeSpeshulTab(...)
  let col = col('.') - 1

  if col == 0 || getline('.')[col - 1] !~ '\k'
    if !pumvisible()
      return "\<Tab>"
    endif
  elseif a:0 > 0
    if !pumvisible()
      return "\<C-x>\<C-u>"
    endif

    if a:1 == "forward"
      return "\<C-n>"
    else
      return "\<C-p>"
    endif
  endif
endfunction

"" https://vim.fandom.com/wiki/Convert_between_hex_and_decimal
" Adapted hex format
function! Dec2hex(arg)
  return printf('%02x', a:arg + 0)
endfunction

function! Hex2dec(arg)
  return (a:arg =~? '^0x') ? a:arg + 0 : ('0x'.a:arg) + 0
endfunction

:source ~/.config/nvim/config/colors.vim
:source ~/.config/nvim/config/mjthl.vim
:source ~/.config/nvim/config/mjttab.vim
:source ~/.config/nvim/config/mjtabbrev.vim
:source ~/.config/nvim/config/mjtmaps.vim
:source ~/.config/nvim/config/statusline.vim
:source ~/.config/nvim/config/tabline.vim
:source ~/.config/nvim/config/omnisharp.vim
" XXX: These don't seem to work, they're here to remind me they should
:lua require('init_lsp')
:lua setup_servers()

" EOF

