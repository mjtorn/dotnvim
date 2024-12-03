" Vim color file - ir_black
" Generated by http://bytefluent.com/vivify 2014-01-21
set background=dark
if version > 580
	hi clear
	if exists("syntax_on")
		syntax reset
	endif
endif

set t_Co=256
let g:colors_name = "ir_black"

hi IncSearch cterm=reverse gui=reverse
hi WildMenu guifg=#00ff00 guibg=#ffff00 guisp=#ffff00 gui=NONE ctermfg=10 ctermbg=11 cterm=NONE
hi SignColumn ctermfg=14 ctermbg=242 guifg=Cyan guibg=Grey
hi SpecialComment guifg=#E18964 guibg=NONE guisp=NONE gui=NONE ctermfg=173 ctermbg=NONE cterm=NONE
hi Typedef guifg=#FFFFB6 guibg=NONE guisp=NONE gui=NONE ctermfg=229 ctermbg=NONE cterm=NONE
hi Title guifg=#f6f3e8 guibg=NONE guisp=NONE gui=bold ctermfg=230 ctermbg=NONE cterm=bold
hi Folded guifg=#a0a8b0 guibg=#384048 guisp=#384048 gui=NONE ctermfg=103 ctermbg=238 cterm=NONE
hi PreCondit guifg=#96CBFE guibg=NONE guisp=NONE gui=NONE ctermfg=117 ctermbg=NONE cterm=NONE
hi Include guifg=#96CBFE guibg=NONE guisp=NONE gui=NONE ctermfg=117 ctermbg=NONE cterm=NONE
"hi TabLineSel -- no settings --
hi StatusLineNC guifg=NONE guibg=#202020 guisp=#202020 gui=NONE ctermfg=NONE ctermbg=NONE cterm=NONE
"hi CTagsMember -- no settings --
hi NonText guifg=#070707 guibg=#000000 guisp=#000000 gui=NONE ctermfg=232 ctermbg=NONE cterm=NONE
"hi CTagsGlobalConstant -- no settings --
hi DiffText cterm=bold ctermbg=9 gui=bold guibg=Red " TODO: guifg
hi ErrorMsg guifg=#ffffff guibg=#FF6C60 guisp=#FF6C60 gui=NONE ctermfg=15 ctermbg=9 cterm=NONE
hi Ignore ctermfg=0 guifg=bg
hi Debug guifg=#E18964 guibg=NONE guisp=NONE gui=NONE ctermfg=173 ctermbg=NONE cterm=NONE
hi PMenuSbar guifg=#000000 guibg=#ffffff guisp=#ffffff gui=NONE ctermfg=NONE ctermbg=15 cterm=NONE
hi Identifier guifg=#C6C5FE guibg=NONE guisp=NONE gui=NONE ctermfg=189 ctermbg=NONE cterm=NONE
hi SpecialChar guifg=#E18964 guibg=NONE guisp=NONE gui=NONE ctermfg=173 ctermbg=NONE cterm=NONE
hi Conditional guifg=#6699CC guibg=NONE guisp=NONE gui=NONE ctermfg=68 ctermbg=NONE cterm=NONE
hi StorageClass guifg=#FFFFB6 guibg=NONE guisp=NONE gui=NONE ctermfg=229 ctermbg=NONE cterm=NONE
hi Todo guifg=#8f8f8f guibg=NONE guisp=NONE gui=NONE ctermfg=245 ctermbg=NONE cterm=NONE
hi Special guifg=#E18964 guibg=NONE guisp=NONE gui=NONE ctermfg=173 ctermbg=NONE cterm=NONE
hi LineNr guifg=#8a8a8a guibg=#000000 guisp=#000000 gui=NONE ctermfg=245 ctermbg=NONE cterm=NONE
hi StatusLine guifg=#ffffff guibg=#6c6c6c guisp=#202020 ctermfg=256 ctermbg=242 cterm=NONE
hi Normal guifg=#ffffd7 guibg=#000000 guisp=#000000 gui=NONE ctermfg=230 ctermbg=NONE cterm=NONE
hi Label guifg=#6699CC guibg=NONE guisp=NONE gui=NONE ctermfg=68 ctermbg=NONE cterm=NONE
"hi CTagsImport -- no settings --
hi PMenuSel guifg=#000000 guibg=#cae682 guisp=#cae682 gui=NONE ctermfg=NONE ctermbg=150 cterm=NONE
hi Search guifg=NONE guibg=#2F2F00 guisp=#2F2F00 gui=underline ctermfg=NONE ctermbg=58 cterm=underline
"hi CTagsGlobalVariable -- no settings --
hi Delimiter guifg=#00A0A0 guibg=NONE guisp=NONE gui=NONE ctermfg=37 ctermbg=NONE cterm=NONE
hi Statement guifg=#6699CC guibg=NONE guisp=NONE gui=NONE ctermfg=68 ctermbg=NONE cterm=NONE
hi SpellRare ctermbg=13 gui=undercurl guisp=Magenta
"hi EnumerationValue -- no settings --
hi Comment guifg=#87ffaf guibg=NONE guisp=NONE gui=NONE ctermfg=lightgreen ctermbg=NONE cterm=NONE
hi Character guifg=#afd7af guibg=NONE guisp=NONE gui=NONE ctermfg=151 ctermbg=NONE cterm=NONE
hi Float guifg=#FF73FD guibg=NONE guisp=NONE gui=NONE ctermfg=207 ctermbg=NONE cterm=NONE
hi Number guifg=#FF73FD guibg=NONE guisp=NONE gui=NONE ctermfg=207 ctermbg=NONE cterm=NONE
hi Boolean guifg=#99CC99 guibg=NONE guisp=NONE gui=NONE ctermfg=151 ctermbg=NONE cterm=NONE
hi Operator guifg=#ffffff guibg=NONE guisp=NONE gui=NONE ctermfg=15 ctermbg=NONE cterm=NONE
hi CursorLine guifg=NONE guibg=#121212 guisp=#121212 gui=NONE ctermfg=NONE ctermbg=233 cterm=NONE
"hi Union -- no settings --
hi TabLineFill cterm=reverse gui=reverse
hi Question ctermfg=121 gui=bold guifg=#87ffaf
hi WarningMsg guifg=#ffffff guibg=#FF6C60 guisp=#FF6C60 gui=NONE ctermfg=15 ctermbg=9 cterm=NONE
"hi VisualNOS -- no settings --
hi DiffDelete ctermfg=12 ctermbg=6 gui=bold guifg=Blue guibg=DarkCyan
hi ModeMsg guifg=#000000 guibg=#C6C5FE guisp=#C6C5FE gui=NONE ctermfg=NONE ctermbg=189 cterm=NONE
hi CursorColumn guifg=NONE guibg=#121212 guisp=#121212 gui=NONE ctermfg=NONE ctermbg=233 cterm=NONE
hi Define guifg=#96CBFE guibg=NONE guisp=NONE gui=NONE ctermfg=117 ctermbg=NONE cterm=NONE
hi Function guifg=#FFD2A7 guibg=NONE guisp=NONE gui=NONE ctermfg=223 ctermbg=NONE cterm=NONE
hi FoldColumn ctermfg=14 ctermbg=242 guifg=Cyan guibg=Grey
hi PreProc guifg=#96CBFE guibg=NONE guisp=NONE gui=NONE ctermfg=117 ctermbg=NONE cterm=NONE
"hi EnumerationName -- no settings --
hi Visual guifg=NONE guibg=#008787 guisp=#262D51 gui=NONE ctermfg=NONE ctermbg=30 cterm=NONE
hi MoreMsg ctermfg=121 gui=bold guifg=#87ffaf
hi SpellCap ctermbg=12 gui=undercurl guisp=Blue
hi VertSplit guifg=#202020 guibg=#202020 guisp=#202020 gui=NONE ctermfg=234 ctermbg=234 cterm=NONE
hi Exception guifg=#6699CC guibg=NONE guisp=NONE gui=NONE ctermfg=68 ctermbg=NONE cterm=NONE
hi Keyword guifg=#96CBFE guibg=NONE guisp=NONE gui=NONE ctermfg=117 ctermbg=NONE cterm=NONE
hi Type guifg=#FFFFB6 guibg=NONE guisp=NONE gui=NONE ctermfg=229 ctermbg=NONE cterm=NONE
hi DiffChange ctermbg=5 guibg=DarkMagenta
hi Cursor guifg=#000000 guibg=#ffffff guisp=#ffffff gui=NONE ctermfg=NONE ctermbg=15 cterm=NONE
hi SpellLocal ctermbg=14 gui=undercurl guisp=Cyan
hi Error ctermfg=15 ctermbg=9 guifg=White guibg=Red
hi PMenu guifg=#f6f3e8 guibg=#444444 guisp=#444444 gui=NONE ctermfg=230 ctermbg=238 cterm=NONE
hi SpecialKey guifg=#808080 guibg=#343434 guisp=#343434 gui=NONE ctermfg=8 ctermbg=236 cterm=NONE
hi Constant guifg=#99CC99 guibg=NONE guisp=NONE gui=NONE ctermfg=151 ctermbg=NONE cterm=NONE
"hi DefinedName -- no settings --
hi Tag guifg=#E18964 guibg=NONE guisp=NONE gui=NONE ctermfg=173 ctermbg=NONE cterm=NONE
hi String guifg=#A8FF60 guibg=NONE guisp=NONE gui=NONE ctermfg=155 ctermbg=NONE cterm=NONE
hi PMenuThumb guifg=NONE guibg=#3D3D3D guisp=#3D3D3D gui=NONE ctermfg=NONE ctermbg=237 cterm=NONE
hi MatchParen guifg=#f6f3e8 guibg=#857b6f guisp=#857b6f gui=NONE ctermfg=230 ctermbg=101 cterm=NONE
"hi LocalVariable -- no settings --
hi Repeat guifg=#6699CC guibg=NONE guisp=NONE gui=NONE ctermfg=68 ctermbg=NONE cterm=NONE
hi SpellBad ctermbg=9 gui=undercurl guisp=Red
"hi CTagsClass -- no settings --
hi Directory ctermfg=159 guifg=Cyan
hi Structure guifg=#FFFFB6 guibg=NONE guisp=NONE gui=NONE ctermfg=229 ctermbg=NONE cterm=NONE
hi Macro guifg=#96CBFE guibg=NONE guisp=NONE gui=NONE ctermfg=117 ctermbg=NONE cterm=NONE
hi Underlined cterm=underline ctermfg=81 gui=underline guifg=#80a0ff
hi DiffAdd ctermbg=4 guibg=DarkBlue
hi TabLine cterm=underline ctermfg=15 ctermbg=242 gui=underline guifg=#ffffff guibg=#6c6c6c
hi cursorim guifg=NONE guibg=#90ee90 guisp=#90ee90 gui=NONE ctermfg=NONE ctermbg=120 cterm=NONE
"hi clear -- no settings --
hi lcursor guifg=#000000 guibg=#006400 guisp=#006400 gui=NONE ctermfg=NONE ctermbg=22 cterm=NONE
hi mbenormal guifg=#cfbfad guibg=#2e2e3f guisp=#2e2e3f gui=NONE ctermfg=187 ctermbg=237 cterm=NONE
hi perlspecialstring guifg=#c080d0 guibg=#404040 guisp=#404040 gui=NONE ctermfg=176 ctermbg=238 cterm=NONE
hi doxygenspecial guifg=#fdd090 guibg=NONE guisp=NONE gui=NONE ctermfg=222 ctermbg=NONE cterm=NONE
hi mbechanged guifg=#eeeeee guibg=#2e2e3f guisp=#2e2e3f gui=NONE ctermfg=255 ctermbg=237 cterm=NONE
hi mbevisiblechanged guifg=#eeeeee guibg=#4e4e8f guisp=#4e4e8f gui=NONE ctermfg=255 ctermbg=60 cterm=NONE
hi doxygenparam guifg=#fdd090 guibg=NONE guisp=NONE gui=NONE ctermfg=222 ctermbg=NONE cterm=NONE
hi doxygensmallspecial guifg=#fdd090 guibg=NONE guisp=NONE gui=NONE ctermfg=222 ctermbg=NONE cterm=NONE
hi doxygenprev guifg=#fdd090 guibg=NONE guisp=NONE gui=NONE ctermfg=222 ctermbg=NONE cterm=NONE
hi perlspecialmatch guifg=#c080d0 guibg=#404040 guisp=#404040 gui=NONE ctermfg=176 ctermbg=238 cterm=NONE
hi cformat guifg=#c080d0 guibg=#404040 guisp=#404040 gui=NONE ctermfg=176 ctermbg=238 cterm=NONE
hi doxygenspecialmultilinedesc guifg=#ad600b guibg=NONE guisp=NONE gui=NONE ctermfg=130 ctermbg=NONE cterm=NONE
hi taglisttagname guifg=#808bed guibg=NONE guisp=NONE gui=NONE ctermfg=105 ctermbg=NONE cterm=NONE
hi doxygenbrief guifg=#fdab60 guibg=NONE guisp=NONE gui=NONE ctermfg=215 ctermbg=NONE cterm=NONE
hi mbevisiblenormal guifg=#cfcfcd guibg=#4e4e8f guisp=#4e4e8f gui=NONE ctermfg=252 ctermbg=60 cterm=NONE
hi user2 guifg=#7070a0 guibg=#3e3e5e guisp=#3e3e5e gui=NONE ctermfg=103 ctermbg=60 cterm=NONE
hi user1 guifg=#00ff8b guibg=#3e3e5e guisp=#3e3e5e gui=NONE ctermfg=48 ctermbg=60 cterm=NONE
hi doxygenspecialonelinedesc guifg=#ad600b guibg=NONE guisp=NONE gui=NONE ctermfg=130 ctermbg=NONE cterm=NONE
hi doxygencomment guifg=#ad7b20 guibg=NONE guisp=NONE gui=NONE ctermfg=130 ctermbg=NONE cterm=NONE
hi cspecialcharacter guifg=#c080d0 guibg=#404040 guisp=#404040 gui=NONE ctermfg=176 ctermbg=238 cterm=NONE
hi htmlitalic guifg=#D0D0D0 guibg=#1F1F1F guisp=#1F1F1F gui=italic ctermfg=252 ctermbg=234 cterm=NONE
hi htmlboldunderlineitalic guifg=#D0D0D0 guibg=#1F1F1F guisp=#1F1F1F gui=bold,italic,underline ctermfg=252 ctermbg=234 cterm=bold,underline
hi htmlbolditalic guifg=#D0D0D0 guibg=#1F1F1F guisp=#1F1F1F gui=bold,italic ctermfg=252 ctermbg=234 cterm=bold
hi htmlunderlineitalic guifg=#D0D0D0 guibg=#1F1F1F guisp=#1F1F1F gui=italic,underline ctermfg=252 ctermbg=234 cterm=underline
hi htmlbold guifg=#D0D0D0 guibg=#1F1F1F guisp=#1F1F1F gui=bold ctermfg=252 ctermbg=234 cterm=bold
hi htmlboldunderline guifg=#D0D0D0 guibg=#1F1F1F guisp=#1F1F1F gui=bold,underline ctermfg=252 ctermbg=234 cterm=bold,underline
hi htmlunderline guifg=#D0D0D0 guibg=#1F1F1F guisp=#1F1F1F gui=underline ctermfg=252 ctermbg=234 cterm=underline
"hi default -- no settings --
hi javadocseetag guifg=#CCCCCC guibg=NONE guisp=NONE gui=NONE ctermfg=252 ctermbg=NONE cterm=NONE
hi number guifg=#FF73FD guibg=NONE guisp=NONE gui=NONE ctermfg=207 ctermbg=NONE cterm=NONE
hi keyword guifg=#96CBFE guibg=NONE guisp=NONE gui=NONE ctermfg=117 ctermbg=NONE cterm=NONE
hi rubyescape guifg=#ffffff guibg=NONE guisp=NONE gui=NONE ctermfg=15 ctermbg=NONE cterm=NONE
hi type guifg=#FFFFB6 guibg=NONE guisp=NONE gui=NONE ctermfg=229 ctermbg=NONE cterm=NONE
hi identifier guifg=#C6C5FE guibg=NONE guisp=NONE gui=NONE ctermfg=189 ctermbg=NONE cterm=NONE
hi conditional guifg=#6699CC guibg=NONE guisp=NONE gui=NONE ctermfg=68 ctermbg=NONE cterm=NONE
hi rubystringdelimiter guifg=#336633 guibg=NONE guisp=NONE gui=NONE ctermfg=65 ctermbg=NONE cterm=NONE
hi rubyregexpdelimiter guifg=#FF8000 guibg=NONE guisp=NONE gui=NONE ctermfg=208 ctermbg=NONE cterm=NONE
hi rubyinterpolationdelimiter guifg=#00A0A0 guibg=NONE guisp=NONE gui=NONE ctermfg=37 ctermbg=NONE cterm=NONE
hi rubycontrol guifg=#6699CC guibg=NONE guisp=NONE gui=NONE ctermfg=68 ctermbg=NONE cterm=NONE
hi rubyregexp guifg=#B18A3D guibg=NONE guisp=NONE gui=NONE ctermfg=137 ctermbg=NONE cterm=NONE
hi operator guifg=#ffffff guibg=NONE guisp=NONE gui=NONE ctermfg=15 ctermbg=NONE cterm=NONE
hi longlinewarning guifg=NONE guibg=#371F1C guisp=#371F1C gui=underline ctermfg=NONE ctermbg=237 cterm=underline
hi @variable guifg=NONE

" This was oddly enough not defined
hi ColorColumn cterm=NONE ctermbg=1 ctermfg=0 guibg=#ff0000 guifg=#000000

" NeoVim 0.5 lsp stuff, mostly untested
hi LspDiagnosticsDefaultError guifg=#ffffff guibg=#FF6C60 guisp=#FF6C60 gui=NONE ctermfg=15 ctermbg=9 cterm=NONE
hi LspDiagnosticsDefaultWarning guifg=#ffffff guibg=#FF6C60 guisp=#FF6C60 gui=NONE ctermfg=9 ctermbg=NONE cterm=NONE
hi LspDiagnosticsDefaultInformation guifg=#ffffff guibg=#FF6C60 guisp=#FF6C60 gui=NONE ctermfg=173 ctermbg=NONE cterm=NONE
hi LspDiagnosticsDefaultHint guifg=#ffffff guibg=#FF6C60 guisp=#FF6C60 gui=NONE ctermfg=232 ctermbg=NONE cterm=NONE

hi LspDiagnosticsSignError guifg=#ffffff guibg=#FF6C60 guisp=#FF6C60 gui=NONE ctermfg=15 ctermbg=9 cterm=NONE
hi LspDiagnosticsSignWarning guifg=#ffffff guibg=#FF6C60 guisp=#FF6C60 gui=NONE ctermfg=9 ctermbg=NONE cterm=NONE
hi LspDiagnosticsSignInformation guifg=#ffffff guibg=#FF6C60 guisp=#FF6C60 gui=NONE ctermfg=173 ctermbg=NONE cterm=NONE
hi LspDiagnosticsSignHint guifg=#ffffff guibg=#FF6C60 guisp=#FF6C60 gui=NONE ctermfg=232 ctermbg=NONE cterm=NONE
