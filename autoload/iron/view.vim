function! iron#view#fix_all_windows()
  let curbuf = bufnr('%')
  setlocal nowinfixwidth nowinfixheight
  for buf in range(1, bufnr('$'))
    if buf == curbuf
      continue
    endif
    " if getbufvar(buf, '&buftype') == 'terminal'
    "   continue
    " endif
    if v:version >= 801
      for win in win_findbuf(buf)
        call win_execute(win, 'setlocal winfixwidth winfixheight')
      endfor
    endif
  endfor
endfunction


function! iron#view#split(cmd, size)
  let self = {"cmd": a:cmd, "size": a:size}

  function! self.get_cmd()
    if match(self["cmd"], "vert") != -1
      let size = winwidth(0) * self["size"]
    else
      let size = winheight(0) * self["size"]
    endif
    return self["cmd"] . " " . string(size)
  endfunction

  return self
endfunction
