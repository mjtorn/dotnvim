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

  for i in range(tabpagenr('$'))
    " Tab page number
    let tpn = '[' . i . ']'

    " How much we show
    let show_len = len(tab_titles[i]) - per_tab

    if per_tab < len(tab_titles[i])
      let title = strcharpart(tab_titles[i], show_len, per_tab)
    else
      let title = tab_titles[i]
    endif

    " This determines if we are active
    if i + 1 == tabpagenr()
      let s .= '%#TabLineSel#'
    else
      let s .= '%#TabLine#'
      if show_len < 50
        let title = join(split(tab_titles[i], '.')[:-1], ' ')
        let title = 'balls'
        echom tab_titles[i]
        echom split(tab_titles[i], '.')
        " let title = strcharpart(tab_titles[i], show_len, per_tab)
      endif
    endif

    " Start adding things
    let s .= tpn

    let s .= title

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

