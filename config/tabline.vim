" :help setting-tabline tells us the tabline is a long string

function! CreateTabLabel(n)
  let buflist = tabpagebuflist(a:n)
  let winnr = tabpagewinnr(a:n)

  return bufname(buflist[winnr-1])
endfunction

function! CreateTabArray()
  let tab_titles = []

  for i in range(tabpagenr('$'))
    " The buffer (~= file) name
    call add(tab_titles, CreateTabLabel(i + 1))
  endfor

  return tab_titles
endfunction

function! CreateTabLine()
  let s = ''

  let tab_titles = CreateTabArray()

  " This section should be so much smarter :D
  let per_tab = &columns / len(tab_titles) - 4
  echom ' ' . len(tab_titles) . ' / ' . &columns . ' = ' . per_tab

  for i in range(tabpagenr('$'))
    " This determines if we are active
    if i + 1 == tabpagenr()
      let s .= '%#TabLineSel#'
    else
      let s .= '%#TabLine#'
    endif

    " Tab page number
    let tpn = '[' . i . ']'

    let s .= tpn

    if per_tab < len(tab_titles[i])
      let s .= strcharpart(tab_titles[i], len(tab_titles[i]) - per_tab, per_tab)
    else
      let s .= tab_titles[i]
    endif

    if i != tabpagenr('$')
      let s .= '%#TabLineFill#'
      let s .= ' '
    endif
  endfor

  " fill the rest of the line and reset number
  let s .= '%#TabLineFill#%T'

  return s
endfunction

:set tabline=%!CreateTabLine()

