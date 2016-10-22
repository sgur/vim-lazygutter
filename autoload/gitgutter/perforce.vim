let s:save_cpo = &cpo
set cpo&vim

function! gitgutter#perforce#is_in_a_repo(file)
  " If file is in Perforce, this will return empty string.
  let check_cmd = printf('p4 -q have %s', a:file)
  return empty(system(check_cmd))
endfunction

function! gitgutter#perforce#cmd(file, lines_of_context)
  if !gitgutter#perforce#is_in_a_repo(a:file)
    return ''
  endif
  return printf('p4 diff -du%s %s', a:lines_of_context, a:file)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
