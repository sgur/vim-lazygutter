let s:save_cpo = &cpo
set cpo&vim

function! s:find_dir_of_file(file)
  return finddir('.hg', fnamemodify(a:file, ':h').';')
endfunction

function! s:discard_stdout_and_stderr()
  if !exists('s:discard')
    let null_dev = has('win32') ? 'NUL' : '/dev/null'
    let s:discard = stridx(&shellredir, '%s') > -1
          \ ? printf(&shellredir, null_dev)
          \ : ' >& ' . null_dev
  endif
  return s:discard
endfunction

function! gitgutter#hg#is_in_a_repo(file)
  if exists('b:gitgutter_dir')
    return b:gitgutter_dir != '' ? 1 : 0
  endif
  call {g:gitgutter_system_function}(printf('hg --cwd %s status'
        \ , gitgutter#hg#work_tree_of_file(a:file)))
  let result = {g:gitgutter_system_error_function}() == 0
  let b:gitgutter_dir = result ? s:find_dir_of_file(a:file) : ''
  return result
endfunction

function! gitgutter#hg#dir_of_file(file)
  return {g:gitgutter_shellescape_function}(s:find_dir_of_file(a:file))
endfunction

function! gitgutter#hg#work_tree_of_file(file)
  return shellescape(fnamemodify(s:find_dir_of_file(a:file), ':h'))
endfunction

function! gitgutter#hg#run_diff(file)
  let diff = {g:gitgutter_system_function}
        \ (printf('hg --cwd %s diff -g -U0 %s %s'
        \ , gitgutter#git#work_tree_of_file(a:file)
        \ , g:gitgutter_diff_args
        \ , {g:gitgutter_shellescape_function}(a:file)))
  return filter(split(diff, '\r\n\|\n\|\r'), 'v:val =~ "^@@"')
endfunction
let &cpo = s:save_cpo
unlet s:save_cpo
