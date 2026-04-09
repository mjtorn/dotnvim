if exists("g:did_load_filetypes")
  finish
endif

" Common-ish extensions people use for EDIFACT/EDI payloads
augroup ftdetect_edifact
  autocmd!
  autocmd BufNewFile,BufRead
        \ *.edifact,*.edi,*.edf,*.un,*.une,*.unh,*.unb,*.inv,*.invoic
        \ setfiletype edifact

  " Content-based detection (handles files with no/odd extension)
  " - UNA:+.? '  (service string advice)
  " - UNB+...    (interchange header)
  autocmd BufNewFile,BufRead *
        \ if getline(1) =~# '^\s*UNA.\{6}$' || getline(1) =~# '^\s*UNB\ze[+]' |
        \   setfiletype edifact |
        \ endif
augroup END
