let s:file = ''

function! gitgutter#utility#warn(message)
  echohl WarningMsg
  echomsg 'vim-gitgutter: ' . a:message
  echohl None
  let b:warningmsg = a:message
endfunction

function! gitgutter#utility#is_active()
  return g:gitgutter_enabled && gitgutter#utility#exists_file()
endfunction

" A replacement for the built-in `shellescape(arg)`.
"
" Recent versions of Vim handle shell escaping pretty well.  However older
" versions aren't as good.  This attempts to do the right thing.
"
" See:
" https://github.com/tpope/vim-fugitive/blob/8f0b8edfbd246c0026b7a2388e1d883d579ac7f6/plugin/fugitive.vim#L29-L37
function! gitgutter#utility#shellescape(arg)
  if a:arg =~ '^[A-Za-z0-9_/.-]\+$'
    return a:arg
  elseif &shell =~# 'cmd'
    return '"' . substitute(substitute(a:arg, '"', '""', 'g'), '%', '"%"', 'g') . '"'
  else
    return shellescape(a:arg)
  endif
endfunction

function! gitgutter#utility#current_file()
  return expand('%:p')
endfunction

function! gitgutter#utility#set_file(file)
  let s:file = escape(a:file, ',[]{}')
endfunction

function! gitgutter#utility#file()
  return s:file
endfunction

function! gitgutter#utility#filename()
  return fnamemodify(s:file, ':t')
endfunction

function! gitgutter#utility#directory_of_file()
  return fnamemodify(s:file, ':h')
endfunction

function! gitgutter#utility#exists_file()
  return filereadable(gitgutter#utility#file())
endfunction

function! gitgutter#utility#has_unsaved_changes(file)
  return getbufvar(a:file, "&mod")
endfunction

function! gitgutter#utility#has_fresh_changes(file)
  return getbufvar(a:file, 'changedtick') != getbufvar(a:file, 'gitgutter_last_tick')
endfunction

function! gitgutter#utility#save_last_seen_change(file)
  call setbufvar(a:file, 'gitgutter_last_tick', getbufvar(a:file, 'changedtick'))
endfunction

function! gitgutter#utility#buffer_contents()
  if &fileformat ==# "dos"
    let eol = "\r\n"
  elseif &fileformat ==# "mac"
    let eol = "\r"
  else
    let eol = "\n"
  endif
  return join(getbufline(s:file, 1, '$'), eol) . eol
endfunction

function! gitgutter#utility#shell_error()
  return v:shell_error
endfunction

function! gitgutter#utility#system(cmd, ...)
  return (a:0 == 0) ? system(a:cmd) : system(a:cmd, a:1)
endfunction

function! gitgutter#utility#file_relative_to_repo_root()
  let file_path_relative_to_repo_root = getbufvar(s:file, 'gitgutter_repo_relative_path')
  if empty(file_path_relative_to_repo_root)
    let dir_path_relative_to_repo_root = gitgutter#utility#system(gitgutter#utility#command_in_directory_of_file('git rev-parse --show-prefix'))
    let dir_path_relative_to_repo_root = gitgutter#utility#strip_trailing_new_line(dir_path_relative_to_repo_root)
    let file_path_relative_to_repo_root = dir_path_relative_to_repo_root . gitgutter#utility#filename()
    call setbufvar(s:file, 'gitgutter_repo_relative_path', file_path_relative_to_repo_root)
  endif
  return file_path_relative_to_repo_root
endfunction

function! gitgutter#utility#command_in_directory_of_file(cmd)
  return 'cd ' . gitgutter#utility#shellescape(gitgutter#utility#directory_of_file()) . ' && ' . a:cmd
endfunction

function! gitgutter#utility#highlight_name_for_change(text)
  if a:text ==# 'added'
    return 'GitGutterLineAdded'
  elseif a:text ==# 'removed'
    return 'GitGutterLineRemoved'
  elseif a:text ==# 'removed_first_line'
    return 'GitGutterLineRemovedFirstLine'
  elseif a:text ==# 'modified'
    return 'GitGutterLineModified'
  elseif a:text ==# 'modified_removed'
    return 'GitGutterLineModifiedRemoved'
  endif
endfunction

function! gitgutter#utility#strip_trailing_new_line(line)
  return substitute(a:line, '\n$', '', '')
endfunction
