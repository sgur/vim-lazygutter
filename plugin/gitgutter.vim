if exists('g:loaded_gitgutter') || !executable('git') || !has('signs') || &cp
  finish
endif
let g:loaded_gitgutter = 1

" Initialisation {{{

function! s:SID_PREFIX()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction

function! s:shell_error()
  return v:shell_error
endfunction

function! s:set(var, default)
  let g:{a:var} = get(g:, a:var, a:default)
endfunction

call s:set('gitgutter_enabled',               1)
call s:set('gitgutter_signs',                 1)
call s:set('gitgutter_highlight_lines',       0)
call s:set('gitgutter_sign_column_always',    0)
call s:set('gitgutter_eager' ,                1)
call s:set('gitgutter_sign_added',            '+')
call s:set('gitgutter_sign_modified',         '~')
call s:set('gitgutter_sign_removed',          '_')
call s:set('gitgutter_sign_modified_removed', '~_')
call s:set('gitgutter_diff_args',             '')
call s:set('gitgutter_system_function',       'system')
call s:set('gitgutter_system_error_function', s:SID_PREFIX() .'shell_error')
call s:set('gitgutter_shellescape_function',  'shellescape')
call s:set('gitgutter_sign_readonly_always',  1)

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
