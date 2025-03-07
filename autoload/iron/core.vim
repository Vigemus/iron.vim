function! s:GetReplSizeCmd(split_type)
  return {
    \ 'vertical': 'vertical resize ' . &columns * g:iron_repl_size["vertical"],
    \ 'horizontal': 'resize ' . &lines * g:iron_repl_size["horizontal"],
  \}[a:split_type] 
endfunction


function! iron#core#new_repl(split_type)
  let current_win_id = win_getid()

  let ft = &filetype
  if empty(ft)
    let ft = "_no_ft"
  endif
  
  let split_type = a:split_type
  if a:split_type == "toggle"
    let split_type = g:iron_repl_default
  endif

  execute "term"
  execute 'set filetype=iron_' . ft

  let g:iron_repl_meta[ft] = {
    \ "buf_id": bufnr('%'),
    \ "buf_ft": 'iron_' . ft,
    \ "repl_open_cmd": g:iron_repl_open_cmd[split_type],
    \ "repl_size_cmd": s:GetReplSizeCmd(split_type),
    \}

  if ft == "_no_ft"
    let repl_def = &shell . " --login"
    call term_sendkeys(g:iron_repl_meta[ft]["buf_id"], repl_def . "\n")
    let g:iron_repl_meta[ft]["repl_def"] = repl_def 

  elseif has_key(g:iron_repl_def, ft)
    if type(g:iron_repl_def[ft]) ==  3
      for shell_cmd in g:iron_repl_def[ft]
        call term_sendkeys(g:iron_repl_meta[ft]["buf_id"], shell_cmd . "\n")
      endfor
    else
        call term_sendkeys(
          \ g:iron_repl_meta[ft]["buf_id"], g:iron_repl_def[ft] . "\n"
          \ )
    endif

    let g:iron_repl_meta[ft]["repl_def"] = g:iron_repl_def[ft]

  else
    call term_sendkeys(g:iron_repl_meta[ft]["buf_id"], ft . "\n")
    let g:iron_repl_meta[ft]["repl_def"] = ft . "\n"
  endif
  
  setlocal bufhidden=hide

  for key in keys(g:iron_repl_meta)
    execute 'autocmd ExitPre * execute ":bd! " . g:iron_repl_meta["' . key . '"]["buf_id"]'
  endfor

  set winfixheight
  set winfixwidth
  call win_gotoid(current_win_id)
  execute bufwinnr(g:iron_repl_meta[ft]["buf_id"]) . "wincmd c"
endfunction


function! iron#core#toggle_repl(split_type)
  let current_win_id = win_getid()

  let ft = &filetype
  if empty(ft)
    let ft = "_no_ft"
  endif

  if index(keys(g:iron_repl_meta), ft) != -1
    if a:split_type != "toggle"
      let g:iron_repl_meta[ft]["repl_open_cmd"] = g:iron_repl_open_cmd[a:split_type]
      let g:iron_repl_meta[ft]["repl_size_cmd"] = s:GetReplSizeCmd(a:split_type)
    endif

    let win_id = bufwinnr(g:iron_repl_meta[ft]["buf_id"])

    if win_id > 0
      execute win_id . "wincmd c"
      return

    else
      execute g:iron_repl_meta[ft]["repl_open_cmd"] . " sbuffer " . g:iron_repl_meta[ft]["buf_id"]
      execute g:iron_repl_meta[ft]["repl_size_cmd"]
    endif

  else
    call iron#core#new_repl(a:split_type)
    call iron#core#toggle_repl(a:split_type)
  endif

  set winfixheight
  set winfixwidth
  call win_gotoid(current_win_id)
endfunction


function! iron#core#kill_repl()
  let ft = &filetype
  if empty(ft)
    let ft = "_no_ft"
  endif

  if index(keys(g:iron_repl_meta), ft) != -1
    execute ":bd! " . g:iron_repl_meta[ft]["buf_id"]
    let _ = remove(g:iron_repl_meta , ft)
  endif
endfunction


function! iron#core#restart_repl()
  let ft = &filetype
  if empty(ft)
    let ft = "_no_ft"
  endif
  if index(keys(g:iron_repl_meta), ft) != -1
    let meta = g:iron_repl_meta[ft]
    call iron#core#kill_repl()
    call iron#core#new_repl("toggle")
    let meta["buf_id"] = g:iron_repl_meta[ft]["buf_id"]
    let g:iron_repl_meta[ft] = meta
    call iron#core#toggle_repl("toggle")
  endif
endfunction


function! iron#core#format(lines, kwargs)
  let result = []

  let exceptions = {}
  if has_key(a:kwargs, "exceptions")
    let exceptions = a:kwargs["exceptions"]
  endif 

  let indent_open = 0

  for line in a:lines
    if iron#helpers#string_is_empty(line) == 1
      continue
    endif

    if iron#helpers#string_is_indented(line) == 1
      let indent_open = 1
      call add(result, line . "\n")

    elseif iron#helpers#starts_with_exception(line, exceptions)
      let indent_open = indent_open
      call add(result, line . "\n")

    else  " string is not indented and does not start with an exception
      if indent_open == 1 " first line after a block of indentation
        call add(result, "\r")
        call add(result, line . "\n")
        let indent_open = 0
      else
        call add(result, line . "\n")
      endif
    endif
  
  endfor
  
  if indent_open
    call add(result, "\r")
  endif

  return result 
endfunction


function! iron#core#send(lines)
  let ft = &filetype
  if empty(ft)
    let ft = "_no_ft"
  endif

  if index(keys(g:iron_repl_meta), ft)  == -1
    return
  endif

  if !exists('*IronFormat')
    return
  endif
  
  if type(a:lines) == 3
    let result = IronFormat(a:lines)
  else
    let result = [a:lines]
  endif

  for line in result
    call term_sendkeys(g:iron_repl_meta[ft]["buf_id"], line)
    call term_wait(g:iron_repl_meta[ft]["buf_id"], 5)
    redraw
  endfor
endfunction
