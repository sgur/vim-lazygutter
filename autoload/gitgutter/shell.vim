let s:save_cpo = &cpo
set cpo&vim

let s:receivers = {}

function! gitgutter#shell#receivers()
 return s:receivers
endfunction

let s:is_win = has('win32') || has('win64')
let s:is_mac = !s:is_win && (has('mac') || has('macunix') || has('gui_macvim')
      \ || (!isdirectory('/proc') && executable('sw_vers')))

if has('gui_running') && s:is_mac
  if executable('mvim')
    let s:executable = 'mvim'
  endif
elseif executable('vim')
  let s:executable = 'vim'
endif

function! s:vim_executable()
  if !exists('s:executable')
    throw 'asyncshell: executable not found'
  endif
  return s:executable . ' -N -u NONE --noplugin'
endfunction

function! s:shellredir(temp_file)
  return stridx(&shellredir, '%s') > -1
        \? printf(&shellredir, a:temp_file)
        \: (' >& ' . a:temp_file)
endfunction

function! s:system(cmd, handler)
  let temp_file = tempname()
  let temp_id = fnamemodify(temp_file, ':t:r')
  let s:receivers[temp_id] =
        \ { 'is_finished' : 0
        \ , 'cmd': a:cmd
        \ , 'result' : []
        \ , 'handler' : a:handler
        \ , 'bufnr' : bufnr('%')
        \ , 'temp_file' : temp_file}
  if type(a:cmd) == type([])
    let target = join(map(a:cmd, 'v:val . s:shellredir(temp_file)'), ' && ')
  else
    let target = a:cmd . s:shellredir(temp_file)
  endif
  let exec_cmd = '(' . (s:is_win ? 'title ' . temp_id . '& ' : '') . target . ')'
  let vim_cmd = printf('%s --servername %s --remote-expr "GitGutter__OnDone(''%s'')"'
        \ , s:vim_executable(), v:servername, temp_id)
  if s:is_win
    silent execute printf('!start /b cmd /c "%s & %s >NUL"', exec_cmd, vim_cmd)
  else
    silent execute printf('! (%s ; %s  >/dev/null) &', exec_cmd, vim_cmd)
  endif
  return temp_id
endfunction

function! s:SID()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction

function! s:split_lines(string)
  return split(a:string, '\r\n\|\n\|\r')
endfunction

function! s:system_fallback(cmd, handler)
  if type(a:cmd) == type([])
    let result = ''
    for l in a:cmd
      let result .= system(l)
      if v:shell_error
        return v:shell_error
      endif
    endfor
  else
    let result = system(a:cmd)
    if v:shell_error
      return v:shell_error
    endif
  endif
  call call(a:handler, [result, bufnr('%')])
  return 0
endfunction

function! GitGutter__OnDone(temp_id)
  let recv = s:receivers[a:temp_id]
  let recv.is_finished = 1
  let temp_file = recv.temp_file
  call call(recv.handler,
        \ [ join(readfile(temp_file), "\n")
        \ , recv.bufnr])
  call delete(temp_file)
  call remove(s:receivers, a:temp_id)
  return ""
endfunction

function! gitgutter#shell#system(cmd, handler)
  return !has('clientserver') || empty(v:servername)
        \ ? s:system_fallback(a:cmd, a:handler)
        \ : s:system(a:cmd, a:handler)
endfunction

function! gitgutter#shell#kill(id)
  if s:is_win
    let result = split(system('tasklist /NH /FO CSV /FI "WINDOWTITLE eq ' . a:id . '"'), '\r\n\|\n\|\r')[0]
    let pid = matchstr(result, '^"[^"]\+","\zs\d\+\ze"')
    call system('taskkill /PID '.pid)
  else
    let results = split(system('ps -u $USER | grep ASYNC' . a:id), '\r\n\|\n\|\r')
    let pids = map(results, 'matchstr(v:val, "\\s\\+\\d\\+\\s\\+\\zs\\d\\+\\ze")')
    call system('kill ' . join(pids, ' '))
  endif
  if !v:shell_error
    call filter(s:receivers, 'v:key != a:id')
  endif
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
