" Vim syntax file
" Language:	Escoria Script
" Maintainer:	Markus Törnqvist
" Last Change:	2018 09 18

" Inspired heavily by Python's syntax stuff

setlocal foldmethod=syntax

"" Pretty much everything Escoria matches this
syn match escWord "\<[a-z_\d]+\>" contained

"" Simple syntax
syn keyword escTodo TODO FIXME XXX
  \ contained
syn keyword escBoolean true false

"" Complex syntax
syn match escPreEvent "^:"
  \ nextgroup=escEvent
syn match escEvent ".*"
  \ contained

" XXX: The space-or-EOL regexps should be one somehow
syn match escCommand "^\s*\<[a-z_-]*\>\s\|^\s*\<[a-z_-]*\>$"

syn region escBlockStart
  \ matchgroup=escCommand
  \ start="^>"
  \ end=" "
syn match escCommand "^> "

syn region escDialogStart
  \ matchgroup=escCommand
  \ start="^\s*?"
  \ end="$"

syn region escString
  \ start=+"+
  \ end=+"+
  \ skip=+\\\\\|\\"+
  \ contains=@Spell
  \ oneline

syn region escDialogChoice
  \ matchgroup=escDialog
  \ start="- "
  \ end=+:"\|$+me=s-1
  \ contains=escWord

"" Mess around with the say command
syn region escSayCommand
  \ matchgroup=escCommand
  \ containedin=escCommand
  \ start="^\s*say .*"
  \ end=" "

syn region escDialogChoice
  \ matchgroup=escSayCommand
  \ containedin=escSayCommand
  \ start="^\s*say [a-z_0-9]\+"
  \ end=+:"+he=e-2

syn match escComment
  \ /#\%(.\%({{{\|}}}\)\@!\)*$/
  \ contains=escTodo,@Spell

"" Folding
" TODO: Event folding
syn region escCommentFold matchgroup=escComment
  \ start='#.*{{{.*$'
  \ end='#.*}}}.*$'
  \ fold transparent

"" colors
hi link escTodo Todo
hi link escBoolean Boolean
hi link escPreEvent Statement
hi link escEvent Function
" It's not really a PreCondit but this is more readable
hi link escCommand PreCondit
hi link escSayCommand PreCondit
hi link escComment Comment
hi link escString String
hi link escDialog PreCondit
hi link escDialogChoice Identifier

