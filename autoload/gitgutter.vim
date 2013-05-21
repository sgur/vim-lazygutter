let s:save_cpo = &cpo
set cpo&vim


let s:highlight_lines = g:gitgutter_highlight_lines

function! s:init()
  if !exists('g:gitgutter_initialised')
    call s:define_sign_column_highlight()
    call s:define_highlights()
    call s:define_signs()

    " Vim doesn't namespace sign ids so every plugin shares the same
    " namespace.  Sign ids are simply integers so to avoid clashes with other
    " signs we guess at a clear run.
    "
    " Note also we currently never reset s:next_sign_id.
    let s:first_sign_id = 3000
    let s:next_sign_id = s:first_sign_id
    let s:sign_ids = {}  " key: filename, value: list of sign ids
    let s:other_signs = []
    let s:dummy_sign_id = 153

    let g:gitgutter_initialised = 1
  endif
endfunction

" }}}

" Utility {{{

function! s:is_active(file)
  return g:gitgutter_enabled && s:exists_file(a:file)
        \ && s:is_in_a_git_repo(a:file)
        \ && (g:gitgutter_eager ? s:is_tracked_by_git(a:file) : 1)
endfunction

function! s:current_file()
  return expand('%:p')
endfunction

function! s:exists_file(file)
  return filereadable(a:file)
endfunction

function! s:find_dir_of_file(file)
  return finddir('.git', fnamemodify(a:file, ':h').';')
endfunction

function! s:git_dir_of_file(file)
  return {g:gitgutter_shellescape_function}(s:find_dir_of_file(a:file))
endfunction

function! s:git_work_tree_of_file(file)
  return {g:gitgutter_shellescape_function}(fnamemodify(s:find_dir_of_file(a:file), ':h'))
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

function! s:is_in_a_git_repo(file)
  if exists('g:loaded_fugitive')
    return fugitive#is_git_dir(exists('b:git_dir') ? b:git_dir : s:find_dir_of_file(a:file))
  endif
  call {g:gitgutter_system_function}(printf('git --git-dir %s --work-tree %s rev-parse %s'
        \ , s:git_dir_of_file(a:file), s:git_work_tree_of_file(a:file)
        \ , s:discard_stdout_and_stderr()))
  return !{g:gitgutter_system_error_function}()
endfunction

function! s:is_tracked_by_git(file)
  call {g:gitgutter_system_function}(printf('git --git-dir %s --work-tree %s ls-files --error-unmatch %s %s'
        \ , s:git_dir_of_file(a:file), s:git_work_tree_of_file(a:file)
        \ , s:discard_stdout_and_stderr(), {g:gitgutter_shellescape_function}(a:file)))
  return !{g:gitgutter_system_error_function}()
endfunction

function! s:shell_error()
  return v:shell_error
endfunction

function! s:differences(hunks)
  return len(a:hunks) != 0
endfunction

function! s:snake_case_to_camel_case(text)
  return substitute(a:text, '\v(.)(\a+)(_(.)(.+))?', '\u\1\l\2\u\4\l\5', '')
endfunction

function! s:buffers()
  return filter(range(1, bufnr('$')), 'buflisted(v:val)')
endfunction

" }}}

" Highlights and signs {{{

function! s:define_sign_column_highlight()
  highlight default link SignColumn LineNr
endfunction

function! s:define_highlights()
  " Highlights used by the signs.
  highlight GitGutterAddDefault          guifg=#009900 guibg=NONE ctermfg=2 ctermbg=NONE
  highlight GitGutterChangeDefault       guifg=#bbbb00 guibg=NONE ctermfg=3 ctermbg=NONE
  highlight GitGutterDeleteDefault       guifg=#ff2222 guibg=NONE ctermfg=1 ctermbg=NONE
  highlight default link GitGutterChangeDeleteDefault GitGutterChangeDefault

  highlight default link GitGutterAdd          GitGutterAddDefault
  highlight default link GitGutterChange       GitGutterChangeDefault
  highlight default link GitGutterDelete       GitGutterDeleteDefault
  highlight default link GitGutterChangeDelete GitGutterChangeDeleteDefault

  " Highlights used for the whole line.
  highlight default link GitGutterAddLine          DiffAdd
  highlight default link GitGutterChangeLine       DiffChange
  highlight default link GitGutterDeleteLine       DiffDelete
  highlight default link GitGutterChangeDeleteLine GitGutterChangeLineDefault
endfunction

function! s:define_signs()
  sign define GitGutterLineAdded
  sign define GitGutterLineModified
  sign define GitGutterLineRemoved
  sign define GitGutterLineModifiedRemoved
  sign define GitGutterDummy

  if g:gitgutter_signs
    call s:define_sign_symbols()
    call s:define_sign_text_highlights()
  endif
  call s:define_sign_line_highlights()
endfunction

function! s:define_sign_symbols()
  exe "sign define GitGutterLineAdded           text=" . g:gitgutter_sign_added
  exe "sign define GitGutterLineModified        text=" . g:gitgutter_sign_modified
  exe "sign define GitGutterLineRemoved         text=" . g:gitgutter_sign_removed
  exe "sign define GitGutterLineModifiedRemoved text=" . g:gitgutter_sign_modified_removed
endfunction

function! s:define_sign_text_highlights()
  sign define GitGutterLineAdded           texthl=GitGutterAdd
  sign define GitGutterLineModified        texthl=GitGutterChange
  sign define GitGutterLineRemoved         texthl=GitGutterDelete
  sign define GitGutterLineModifiedRemoved texthl=GitGutterChangeDelete
endfunction

function! s:define_sign_line_highlights()
  if s:highlight_lines
    sign define GitGutterLineAdded           linehl=GitGutterAddLine
    sign define GitGutterLineModified        linehl=GitGutterChangeLine
    sign define GitGutterLineRemoved         linehl=GitGutterDeleteLine
    sign define GitGutterLineModifiedRemoved linehl=GitGutterChangeDeleteLine
  else
    sign define GitGutterLineAdded           linehl=
    sign define GitGutterLineModified        linehl=
    sign define GitGutterLineRemoved         linehl=
    sign define GitGutterLineModifiedRemoved linehl=
  endif
  redraw!
endfunction

" }}}

" Diff processing {{{

function! s:run_diff(file)
  let diff = {g:gitgutter_system_function}
        \ (printf('git --git-dir %s --work-tree %s diff --no-ext-diff --no-color -U0 %s %s'
        \ , s:git_dir_of_file(a:file)
        \ , s:git_work_tree_of_file(a:file)
        \ , g:gitgutter_diff_args
        \ , {g:gitgutter_shellescape_function}(a:file)))
  return filter(split(diff, '\r\n\|\n\|\r'), 'v:val =~ "^@@"')
endfunction

function! s:parse_diff(diff)
  let hunk_re = '^@@ -\(\d\+\),\?\(\d*\) +\(\d\+\),\?\(\d*\) @@'
  let hunks = []
  for line in a:diff
    let matches = matchlist(line, hunk_re)
    if len(matches) > 0
      let from_line  = str2nr(matches[1])
      let from_count = (matches[2] == '') ? 1 : str2nr(matches[2])
      let to_line    = str2nr(matches[3])
      let to_count   = (matches[4] == '') ? 1 : str2nr(matches[4])
      call add(hunks, [from_line, from_count, to_line, to_count])
    endif
  endfor
  return hunks
endfunction

function! s:process_hunks(hunks)
  let modified_lines = []
  for hunk in a:hunks
    call extend(modified_lines, s:process_hunk(hunk))
  endfor
  return modified_lines
endfunction

function! s:process_hunk(hunk)
  let modifications = []
  let from_line  = a:hunk[0]
  let from_count = a:hunk[1]
  let to_line    = a:hunk[2]
  let to_count   = a:hunk[3]

  if s:is_added(from_count, to_count)
    call s:process_added(modifications, from_count, to_count, to_line)

  elseif s:is_removed(from_count, to_count)
    call s:process_removed(modifications, from_count, to_count, to_line)

  elseif s:is_modified(from_count, to_count)
    call s:process_modified(modifications, from_count, to_count, to_line)

  elseif s:is_modified_and_added(from_count, to_count)
    call s:process_modified_and_added(modifications, from_count, to_count, to_line)

  elseif s:is_modified_and_removed(from_count, to_count)
    call s:process_modified_and_removed(modifications, from_count, to_count, to_line)

  endif
  return modifications
endfunction

" }}}

" Diff utility {{{

function! s:is_added(from_count, to_count)
  return a:from_count == 0 && a:to_count > 0
endfunction

function! s:is_removed(from_count, to_count)
  return a:from_count > 0 && a:to_count == 0
endfunction

function! s:is_modified(from_count, to_count)
  return a:from_count > 0 && a:to_count > 0 && a:from_count == a:to_count
endfunction

function! s:is_modified_and_added(from_count, to_count)
  return a:from_count > 0 && a:to_count > 0 && a:from_count < a:to_count
endfunction

function! s:is_modified_and_removed(from_count, to_count)
  return a:from_count > 0 && a:to_count > 0 && a:from_count > a:to_count
endfunction

function! s:process_added(modifications, from_count, to_count, to_line)
  let offset = 0
  while offset < a:to_count
    let line_number = a:to_line + offset
    call add(a:modifications, [line_number, 'added'])
    let offset += 1
  endwhile
endfunction

function! s:process_removed(modifications, from_count, to_count, to_line)
  call add(a:modifications, [a:to_line, 'removed'])
endfunction

function! s:process_modified(modifications, from_count, to_count, to_line)
  let offset = 0
  while offset < a:to_count
    let line_number = a:to_line + offset
    call add(a:modifications, [line_number, 'modified'])
    let offset += 1
  endwhile
endfunction

function! s:process_modified_and_added(modifications, from_count, to_count, to_line)
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

function! s:process_modified_and_removed(modifications, from_count, to_count, to_line)
  let offset = 0
  while offset < a:to_count
    let line_number = a:to_line + offset
    call add(a:modifications, [line_number, 'modified'])
    let offset += 1
  endwhile
  call add(a:modifications, [a:to_line + offset - 1, 'modified_removed'])
endfunction

" }}}

" Sign processing {{{

function! s:clear_signs(file_name)
  if has_key(s:sign_ids, a:file_name)
    for id in s:sign_ids[a:file_name]
      exe ":sign unplace" id "file=" . a:file_name
    endfor
    let s:sign_ids[a:file_name] = []
  endif
endfunction

" This assumes there are no GitGutter signs in the file.
" If this is untenable we could change the regexp to exclude GitGutter's
" signs.
function! s:find_other_signs(file_name)
  redir => signs
  silent exe ":sign place file=" . a:file_name
  redir END
  let s:other_signs = []
  for sign_line in split(signs, '\n')
    if sign_line =~ '^\s\+\w\+='
      let matches = matchlist(sign_line, '^\s\+\w\+=\(\d\+\)')
      let line_number = str2nr(matches[1])
      call add(s:other_signs, line_number)
    endif
  endfor
endfunction

function! s:show_signs(file_name, modified_lines)
  for line in a:modified_lines
    let line_number = line[0]
    let type = 'GitGutterLine' . s:snake_case_to_camel_case(line[1])
    call s:add_sign(line_number, type, a:file_name)
  endfor
endfunction

function! s:add_sign(line_number, name, file_name)
  let id = s:next_sign_id()
  if !s:is_other_sign(a:line_number)  " Don't clobber other people's signs.
    exe ":sign place" id "line=" . a:line_number "name=" . a:name "file=" . a:file_name
    call s:remember_sign(id, a:file_name)
  endif
endfunction

function! s:next_sign_id()
  let next_id = s:next_sign_id
  let s:next_sign_id += 1
  return next_id
endfunction

function! s:remember_sign(id, file_name)
  if has_key(s:sign_ids, a:file_name)
    let sign_ids_for_file = s:sign_ids[a:file_name]
    call add(sign_ids_for_file, a:id)
  else
    let sign_ids_for_file = [a:id]
  endif
  let s:sign_ids[a:file_name] = sign_ids_for_file
endfunction

function! s:is_other_sign(line_number)
  return index(s:other_signs, a:line_number) == -1 ? 0 : 1
endfunction

function! s:add_dummy_sign(file)
  let last_line = line('$')
  exe ":sign place" s:dummy_sign_id "line=" . (last_line + 1) "name=GitGutterDummy file=" . a:file
endfunction

function! s:remove_dummy_sign(file)
  if exists('s:dummy_sign_id')
    exe ":sign unplace" s:dummy_sign_id "file=" . a:file
  endif
endfunction

" }}}

" Private interface {{{

function! gitgutter#gitgutter_all()
  for buffer_id in tabpagebuflist()
    call gitgutter#gitgutter(expand('#' . buffer_id . ':p'))
  endfor
endfunction

function! gitgutter#gitgutter(...)
  let file = (a:0 > 0) ? a:1 : s:current_file()
  if g:gitgutter_sign_readonly_always
        \ && (!filereadable(file) || getbufvar(bufnr(file), '&readonly') == 1)
    return
  end
  if s:is_active(file)
    call s:init()
    let diff = s:run_diff(file)
    let s:hunks = s:parse_diff(diff)
    let modified_lines = s:process_hunks(s:hunks)
    if g:gitgutter_sign_column_always
      call s:add_dummy_sign(file)
    else
      if s:differences(s:hunks)
        call s:add_dummy_sign(file)  " prevent flicker
      else
        call s:remove_dummy_sign(file)
      endif
    endif
    call s:clear_signs(file)
    call s:find_other_signs(file)
    call s:show_signs(file, modified_lines)
  endif
endfunction

function! gitgutter#disable()
  let g:gitgutter_enabled = 0
  call s:clear_signs(s:current_file())
  call s:remove_dummy_sign()
endfunction

function! gitgutter#enable()
  let g:gitgutter_enabled = 1
  call gitgutter#gitgutter(s:current_file())
endfunction

function! gitgutter#toggle()
  if g:gitgutter_enabled
    call gitgutter#disable()
  else
    call gitgutter#enable()
  endif
endfunction

function! gitgutter#highlight_disable()
  let s:highlight_lines = 0
  call s:define_sign_line_highlights()
endfunction

function! gitgutter#highlight_enable()
  let s:highlight_lines = 1
  call s:define_sign_line_highlights()
endfunction

function! gitgutter#highlight_toggle()
  let s:highlight_lines = (s:highlight_lines ? 0 : 1)
  call s:define_sign_line_highlights()
endfunction

function! gitgutter#next_hunk(file, count)
  if s:is_active(a:file)
    let current_line = line('.')
    let hunk_count = 0
    for hunk in s:hunks
      if hunk[2] > current_line
        let hunk_count += 1
        if hunk_count == a:count
          execute 'normal!' hunk[2] . 'G'
          break
        endif
      endif
    endfor
  endif
endfunction

function! gitgutter#prev_hunk(file, count)
  if s:is_active(a:file)
    let current_line = line('.')
    let hunk_count = 0
    for hunk in reverse(copy(s:hunks))
      if hunk[2] < current_line
        let hunk_count += 1
        if hunk_count == a:count
          execute 'normal!' hunk[2] . 'G'
          break
        endif
      endif
    endfor
  endif
endfunction

function! gitgutter#get_hunks(file)
  return s:is_active(a:file) ? s:hunks : []
endfunction

function! gitgutter#define_sign_column_highlight()
  call s:define_sign_column_highlight()
endfunction

function! gitgutter#define_highlights()
  call s:define_highlights()
endfunction
" }}}


let &cpo = s:save_cpo
unlet s:save_cpo
