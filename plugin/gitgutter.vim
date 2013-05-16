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
call s:set('g:gitgutter_eager' ,                1)
call s:set('g:gitgutter_sign_added',            '+')
call s:set('g:gitgutter_sign_modified',         '~')
call s:set('g:gitgutter_sign_removed',          '_')
call s:set('g:gitgutter_sign_modified_removed', '~_')
call s:set('g:gitgutter_diff_args',             '')
call s:set('g:gitgutter_escape_grep',           0)
call s:set('g:gitgutter_system_function',       'system')
call s:set('g:gitgutter_system_error_function', 's:shell_error')
call s:set('g:gitgutter_shellescape_function',  'shellescape')

" }}}

" Public interface {{{

command GitGutterAll call gitgutter#gitgutter_all()
command GitGutter call gitgutter#gitgutter()
command GitGutterDisable call gitgutter#disable()
command GitGutterEnable call gitgutter#enable()
command GitGutterToggle call gitgutter#toggle()
command GitGutterLineHighlightsDisable call gitgutter#highlight_disable()
command GitGutterLineHighlightsEnable call gitgutter#highlight_enable()
command GitGutterLineHighlightsToggle call gitgutter#highlight_toggle()
command -count=1 GitGutterNextHunk call gitgutter#next_hunk(expand('%'), <count>)
command -count=1 GitGutterPrevHunk call gitgutter#prev_hunk(expand('%'), <count>)

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

nnoremap <silent> <Plug>GitGutterNextHunk :<C-U>execute v:count1 . "GitGutterNextHunk"<CR>
nnoremap <silent> <Plug>GitGutterPrevHunk :<C-U>execute v:count1 . "GitGutterPrevHunk"<CR>

if !hasmapto('<Plug>GitGutterNextHunk') && maparg(']h', 'n') ==# ''
  nmap ]h <Plug>GitGutterNextHunk
  nmap [h <Plug>GitGutterPrevHunk
endif

augroup gitgutter
  autocmd!
  if g:gitgutter_eager
    autocmd BufEnter,BufWritePost,FileWritePost * call gitgutter#gitgutter()
    autocmd TabEnter * call gitgutter#gitgutter_all()
    if !has('gui_win32')
      autocmd FocusGained * call gitgutter#gitgutter_all()
    endif
  else
    autocmd BufReadPost,BufWritePost,FileReadPost,FileWritePost * call gitgutter#gitgutter()
  endif
  autocmd ColorScheme * call gitgutter#define_sign_column_highlight() | call gitgutter#define_highlights()
augroup END

" }}}

" vim:set et sw=2 fdm=marker:
