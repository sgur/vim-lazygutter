if exists('g:loaded_gitgutter') || !executable('git') || !has('signs') || &cp
  finish
endif
let g:loaded_gitgutter = 1

" Initialisation {{{

function! s:set(var, default)
  if !exists(a:var)
    if type(a:default)
      exe 'let' a:var '=' string(a:default)
    else
      exe 'let' a:var '=' a:default
    endif
  endif
endfunction

call s:set('g:gitgutter_enabled',               1)
call s:set('g:gitgutter_signs',                 1)
call s:set('g:gitgutter_highlight_lines',       0)
call s:set('g:gitgutter_sign_column_always',    0)
call s:set('g:gitgutter_on_bufenter',           1)
call s:set('g:gitgutter_all_on_focusgained',    1)
call s:set('g:gitgutter_sign_added',            '+')
call s:set('g:gitgutter_sign_modified',         '~')
call s:set('g:gitgutter_sign_removed',          '_')
call s:set('g:gitgutter_sign_modified_removed', '~_')
call s:set('g:gitgutter_diff_args',             '')
call s:set('g:gitgutter_escape_grep',           0)
call s:set('g:gitgutter_system_function',       'system')
call s:set('g:gitgutter_system_error_function', 's:shell_error')

" }}}

" Public interface {{{

function! GitGutterAll()
  call gitgutter#gitgutter_all()
endfunction
command GitGutterAll call GitGutterAll()

function! GitGutter(file)
  call gitgutter#gitgutter(a:file)
endfunction
command GitGutter call GitGutter(gitgutter#current_file())

function! GitGutterDisable()
  call gitgutter#disable()
endfunction
command GitGutterDisable call GitGutterDisable()

function! GitGutterEnable()
  call gitgutter#enable()
endfunction
command GitGutterEnable call GitGutterEnable()

function! GitGutterToggle()
  call gitgutter#toggle()
endfunction
command GitGutterToggle call GitGutterToggle()

function! GitGutterLineHighlightsDisable()
  call gitgutter#highlight_disable()
endfunction
command GitGutterLineHighlightsDisable call GitGutterLineHighlightsDisable()

function! GitGutterLineHighlightsEnable()
  call gitgutter#highlight_enable()
endfunction
command GitGutterLineHighlightsEnable call GitGutterLineHighlightsEnable()

function! GitGutterLineHighlightsToggle()
  call gitgutter#highlight_toggle()
endfunction
command GitGutterLineHighlightsToggle call GitGutterLineHighlightsToggle()

function! GitGutterNextHunk(count)
  call gitgutter#next_hunk(a:count)
endfunction
command -count=1 GitGutterNextHunk call GitGutterNextHunk(<count>)

function! GitGutterPrevHunk(count)
  call gitgutter#prev_hunk(a:count)
endfunction
command -count=1 GitGutterPrevHunk call GitGutterPrevHunk(<count>)

" Returns the git-diff hunks for the file or an empty list if there
" aren't any hunks.
"
" The return value is a list of lists.  There is one inner list per hunk.
"
"   [
"     [from_line, from_count, to_line, to_count],
"     [from_line, from_count, to_line, to_count],
"     ...
"   ]
"
" where:
"
" `from`  - refers to the staged file
" `to`    - refers to the working tree's file
" `line`  - refers to the line number where the change starts
" `count` - refers to the number of lines the change covers
function! GitGutterGetHunks()
  return gitgutter#get_hunks()
endfunction

augroup gitgutter
  autocmd!
  if g:gitgutter_on_bufenter
    autocmd BufEnter,BufWritePost,FileWritePost * call GitGutter(gitgutter#current_file())
  else
    autocmd BufReadPost,BufWritePost,FileReadPost,FileWritePost * call GitGutter(gitgutter#current_file())
  endif
  if g:gitgutter_all_on_focusgained
    if !has('gui_win32')
      autocmd FocusGained * call GitGutterAll()
    endif
    autocmd TabEnter * call GitGutterAll()
  endif
  autocmd ColorScheme * call gitgutter#define_sign_column_highlight() | call gitgutter#define_highlights()
augroup END

" }}}

" vim:set et sw=2 fdm=marker:
