let s:hunk_re = '^@@ -\(\d\+\),\?\(\d*\) +\(\d\+\),\?\(\d*\) @@'


function! gitgutter#diff#run_diff()
  " Wrap compound command in parentheses to make Windows happy.

  let fname = gitgutter#utility#shellescape(gitgutter#utility#filename())
  let cmd = ''
  for repo in ['hg', 'git']
    if gitgutter#{repo}#is_in_a_repo(fname)
      let cmd = gitgutter#{repo}#cmd(fname)
    endif
  endfor

  if !empty(cmd)
    call gitgutter#shell#system(gitgutter#utility#command_in_directory_of_file(cmd), 'gitgutter#post_hook')
  endif
endfunction

function! gitgutter#diff#parse_diff(diff)
  let hunks = []
  for line in split(a:diff, '\n')
    let hunk_info = gitgutter#diff#parse_hunk(line)
    if len(hunk_info) == 4
      call add(hunks, hunk_info)
    endif
  endfor
  return hunks
endfunction

function! gitgutter#diff#parse_hunk(line)
  let matches = matchlist(a:line, s:hunk_re)
  if len(matches) > 0
    let from_line  = str2nr(matches[1])
    let from_count = (matches[2] == '') ? 1 : str2nr(matches[2])
    let to_line    = str2nr(matches[3])
    let to_count   = (matches[4] == '') ? 1 : str2nr(matches[4])
    return [from_line, from_count, to_line, to_count]
  else
    return []
  end
endfunction

function! gitgutter#diff#process_hunks(hunks)
  call gitgutter#hunk#reset()
  let modified_lines = []
  for hunk in a:hunks
    call extend(modified_lines, gitgutter#diff#process_hunk(hunk))
  endfor
  return modified_lines
endfunction

" Returns [ [<line_number (number)>, <name (string)>], ...]
function! gitgutter#diff#process_hunk(hunk)
  let modifications = []
  let from_line  = a:hunk[0]
  let from_count = a:hunk[1]
  let to_line    = a:hunk[2]
  let to_count   = a:hunk[3]

  if gitgutter#diff#is_added(from_count, to_count)
    call gitgutter#diff#process_added(modifications, from_count, to_count, to_line)
    call gitgutter#hunk#increment_lines_added(to_count)

  elseif gitgutter#diff#is_removed(from_count, to_count)
    call gitgutter#diff#process_removed(modifications, from_count, to_count, to_line)
    call gitgutter#hunk#increment_lines_removed(from_count)

  elseif gitgutter#diff#is_modified(from_count, to_count)
    call gitgutter#diff#process_modified(modifications, from_count, to_count, to_line)
    call gitgutter#hunk#increment_lines_modified(to_count)

  elseif gitgutter#diff#is_modified_and_added(from_count, to_count)
    call gitgutter#diff#process_modified_and_added(modifications, from_count, to_count, to_line)
    call gitgutter#hunk#increment_lines_added(to_count - from_count)
    call gitgutter#hunk#increment_lines_modified(from_count)

  elseif gitgutter#diff#is_modified_and_removed(from_count, to_count)
    call gitgutter#diff#process_modified_and_removed(modifications, from_count, to_count, to_line)
    call gitgutter#hunk#increment_lines_modified(to_count)
    call gitgutter#hunk#increment_lines_removed(from_count - to_count)

  endif
  return modifications
endfunction

function! gitgutter#diff#is_added(from_count, to_count)
  return a:from_count == 0 && a:to_count > 0
endfunction

function! gitgutter#diff#is_removed(from_count, to_count)
  return a:from_count > 0 && a:to_count == 0
endfunction

function! gitgutter#diff#is_modified(from_count, to_count)
  return a:from_count > 0 && a:to_count > 0 && a:from_count == a:to_count
endfunction

function! gitgutter#diff#is_modified_and_added(from_count, to_count)
  return a:from_count > 0 && a:to_count > 0 && a:from_count < a:to_count
endfunction

function! gitgutter#diff#is_modified_and_removed(from_count, to_count)
  return a:from_count > 0 && a:to_count > 0 && a:from_count > a:to_count
endfunction

function! gitgutter#diff#process_added(modifications, from_count, to_count, to_line)
  let offset = 0
  while offset < a:to_count
    let line_number = a:to_line + offset
    call add(a:modifications, [line_number, 'added'])
    let offset += 1
  endwhile
endfunction

function! gitgutter#diff#process_removed(modifications, from_count, to_count, to_line)
  if a:to_line == 0
    call add(a:modifications, [1, 'removed_first_line'])
  else
    call add(a:modifications, [a:to_line, 'removed'])
  endif
endfunction

function! gitgutter#diff#process_modified(modifications, from_count, to_count, to_line)
  let offset = 0
  while offset < a:to_count
    let line_number = a:to_line + offset
    call add(a:modifications, [line_number, 'modified'])
    let offset += 1
  endwhile
endfunction

function! gitgutter#diff#process_modified_and_added(modifications, from_count, to_count, to_line)
  let offset = 0
  while offset < a:from_count
    let line_number = a:to_line + offset
    call add(a:modifications, [line_number, 'modified'])
    let offset += 1
  endwhile
  while offset < a:to_count
    let line_number = a:to_line + offset
    call add(a:modifications, [line_number, 'added'])
    let offset += 1
  endwhile
endfunction

function! gitgutter#diff#process_modified_and_removed(modifications, from_count, to_count, to_line)
  let offset = 0
  while offset < a:to_count
    let line_number = a:to_line + offset
    call add(a:modifications, [line_number, 'modified'])
    let offset += 1
  endwhile
  let a:modifications[-1] = [a:to_line + offset - 1, 'modified_removed']
endfunction

function! gitgutter#diff#generate_diff_for_hunk(hunk, keep_header)
  let diff = gitgutter#diff#discard_hunks(gitgutter#diff#run_diff(), a:hunk, a:keep_header)
  if !a:keep_header
    " Discard summary line
    let diff = join(split(diff, '\n')[1:-1], "\n")
  endif
  return diff
endfunction

function! gitgutter#diff#discard_hunks(diff, hunk_to_keep, keep_header)
  let modified_diff = []
  let keep_line = a:keep_header
  for line in split(a:diff, '\n')
    let hunk_info = gitgutter#diff#parse_hunk(line)
    if len(hunk_info) == 4  " start of new hunk
      let keep_line = (hunk_info == a:hunk_to_keep)
    endif
    if keep_line
      call add(modified_diff, line)
    endif
  endfor
  return join(modified_diff, "\n") . "\n"
endfunction
