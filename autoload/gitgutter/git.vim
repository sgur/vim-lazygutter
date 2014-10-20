let s:save_cpo = &cpo
set cpo&vim

function! gitgutter#git#is_in_a_repo(file)
  return !empty(s:find_dir_of_file(a:file))
endfunction

function! gitgutter#git#cmd(file, lines_of_context)
  let check_cmd = printf('git ls-files --error-unmatch %s %s', a:file, s:redir_nulldev)
  let diff_cmd = printf('git diff --no-ext-diff --no-color -U%s %s %s'
        \ , a:lines_of_context, g:gitgutter_diff_args, a:file)
  return printf('(%s && (%s))', check_cmd, diff_cmd)
endfunction

function! s:find_dir_of_file(file)
  let dir = finddir('.git', fnamemodify(a:file, ':p:h').';')
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
