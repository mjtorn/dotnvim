" Assumes common EDIFACT separators: + : ' and release char ?
" Works regardless of Tree-sitter parser availability.

if exists("b:current_syntax")
  finish
endif

" Segment tag at start of a segment/line (e.g. UNB, BGM, DTM, NAD ...)
syntax match edifactSegmentTag /^\s*\zs[A-Z][A-Z0-9]\{1,2}\ze\%([+']\|$\)/

" Separators
syntax match edifactSeparator /[+:'"]/
" Segment terminator explicitly (often ')
syntax match edifactSegmentTerminator /'/

" Release character (escape) in EDIFACT
syntax match edifactReleaseChar /?./

" Numbers (integers/decimals)
syntax match edifactNumber /\v<\d+(\.\d+)?>/

" Common qualifiers/codes (very lightweight):
" things like D:96A:UN, 102, AAA, VAT, KGM, GBP, EN, etc.
syntax match edifactCode /\v<\u{2,4}\d{0,3}\u{0,3}>/

" Link to standard highlight groups
highlight default link edifactSegmentTag Keyword
highlight default link edifactSeparator Delimiter
highlight default link edifactSegmentTerminator Delimiter
highlight default link edifactReleaseChar SpecialChar
highlight default link edifactNumber Number
highlight default link edifactCode Identifier

let b:current_syntax = "edifact"
