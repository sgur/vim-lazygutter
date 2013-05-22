let s:save_cpo = &cpo
set cpo&vim

function! s:find_dir_of_file(file)
  return finddir('.git', fnamemodify(a:file, ':h').';')
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

function! gitgutter#git#is_in_a_repo(file)
  if exists('g:loaded_fugitive')
    return fugitive#is_git_dir(exists('b:git_dir') ? b:git_dir : s:find_dir_of_file(a:file))
  endif
  call {g:gitgutter_system_function}(printf('git --git-dir %s --work-tree %s rev-parse %s'
        \ , gitgutter#git#dir_of_file(a:file), gitgutter#git#work_tree_of_file(a:file)
        \ , s:discard_stdout_and_stderr()))
  return !{g:gitgutter_system_error_function}()
endfunction

function! gitgutter#git#dir_of_file(file)
  return {g:gitgutter_shellescape_function}(s:find_dir_of_file(a:file))
endfunction

function! gitgutter#git#work_tree_of_file(file)
  return {g:gitgutter_shellescape_function}(fnamemodify(s:find_dir_of_file(a:file), ':h'))
endfunction

function! gitgutter#git#run_diff(file)
  let diff = {g:gitgutter_system_function}
        \ (printf('git --git-dir %s --work-tree %s diff --no-ext-diff --no-color -U0 %s %s'
        \ , gitgutter#git#dir_of_file(a:file)
        \ , gitgutter#git#work_tree_of_file(a:file)
        \ , g:gitgutter_diff_args
        \ , {g:gitgutter_shellescape_function}(a:file)))
  return filter(split(diff, '\r\n\|\n\|\r'), 'v:val =~ "^@@"')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo


