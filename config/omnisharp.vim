"" Taken from the README example

" This is required for Unity3D
let g:OmniSharp_server_use_mono = 1

" Seems pretty much everyone uses tabs, and so far I have found no better foldmethod
autocmd BufEnter *.cs setl tabstop=4 noexpandtab autoindent shiftwidth=4 fileencoding=utf-8 foldmethod=indent

augroup omnisharp_commands
  autocmd!

  " Show type information automatically when the cursor stops moving.
  " Note that the type is echoed to the Vim command line, and will overwrite
  " any other messages in this space including e.g. ALE linting messages.
  autocmd CursorHold *.cs OmniSharpTypeLookup

  " Configure the common help thing as well
  autocmd FileType cs nmap K :OmniSharpDocumentation<CR>

  " The following commands are contextual, based on the cursor position.
  autocmd FileType cs nmap <silent> <buffer> gd <Plug>(omnisharp_go_to_definition)
  autocmd FileType cs nmap <silent> <buffer> <Leader>fu <Plug>(omnisharp_find_usages)
  autocmd FileType cs nmap <silent> <buffer> <Leader>fi <Plug>(omnisharp_find_implementations)
  autocmd FileType cs nmap <silent> <buffer> <Leader>pd <Plug>(omnisharp_preview_definition)
  autocmd FileType cs nmap <silent> <buffer> <Leader>pi <Plug>(omnisharp_preview_implementations)
  autocmd FileType cs nmap <silent> <buffer> <Leader>t <Plug>(omnisharp_type_lookup)
  autocmd FileType cs nmap <silent> <buffer> <Leader>d <Plug>(omnisharp_documentation)
  autocmd FileType cs nmap <silent> <buffer> <Leader>fs <Plug>(omnisharp_find_symbol)
  autocmd FileType cs nmap <silent> <buffer> <Leader>fx <Plug>(omnisharp_fix_usings)
  autocmd FileType cs nmap <silent> <buffer> <C-\> <Plug>(omnisharp_signature_help)
  autocmd FileType cs imap <silent> <buffer> <C-\> <Plug>(omnisharp_signature_help)

  " Navigate up and down by method/property/field
  autocmd FileType cs nmap <silent> <buffer> [[ <Plug>(omnisharp_navigate_up)
  autocmd FileType cs nmap <silent> <buffer> ]] <Plug>(omnisharp_navigate_down)
  " Find all code errors/warnings for the current solution and populate the quickfix window
  autocmd FileType cs nmap <silent> <buffer> <Leader>gcc <Plug>(omnisharp_global_code_check)
  " Contextual code actions (uses fzf, vim-clap, CtrlP or unite.vim selector when available)
  autocmd FileType cs nmap <silent> <buffer> <Leader>ca <Plug>(omnisharp_code_actions)
  autocmd FileType cs xmap <silent> <buffer> <Leader>ca <Plug>(omnisharp_code_actions)
  " Repeat the last code action performed (does not use a selector)
  autocmd FileType cs nmap <silent> <buffer> <Leader>. <Plug>(omnisharp_code_action_repeat)
  autocmd FileType cs xmap <silent> <buffer> <Leader>. <Plug>(omnisharp_code_action_repeat)

  autocmd FileType cs nmap <silent> <buffer> <Leader>= <Plug>(omnisharp_code_format)

  autocmd FileType cs nmap <silent> <buffer> <Leader>nm <Plug>(omnisharp_rename)

  autocmd FileType cs nmap <silent> <buffer> <Leader>re <Plug>(omnisharp_restart_server)
  autocmd FileType cs nmap <silent> <buffer> <Leader>st <Plug>(omnisharp_start_server)
  autocmd FileType cs nmap <silent> <buffer> <Leader>sp <Plug>(omnisharp_stop_server)
augroup END

