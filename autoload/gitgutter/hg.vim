let s:save_cpo = &cpo
set cpo&vim

function! gitgutter#hg#is_in_a_repo(file)
  return !empty(s:find_dir_of_file(a:file))
endfunction

function! gitgutter#hg#cmd(file, lines_of_context)
  let check_cmd = printf('hg locate %s %s', a:file, s:redir_nulldev)
  let diff_cmd = printf('hg diff -g -U%s %s %s'
        \ , a:lines_of_context, g:gitgutter_diff_args, a:file)
  return printf('(%s && (%s))', check_cmd, diff_cmd)
endfunction

function! s:find_dir_of_file(file)
  let dir = finddir('.hg', fnamemodify(a:file, ':p:h').';')
  return dir isnot? getcwd() ? dir : ''
endfunction

function! s:redir_null()
  let null_dev = has('win32') ? 'NUL' : '/dev/null'
  return stridx(&shellredir, '%s') > -1
        \ ? printf(&shellredir, null_dev)
        \ : ' >& ' . null_dev
endfunction

let s:redir_nulldev = s:redir_null()

let &cpo = s:save_cpo
unlet s:save_cpo
