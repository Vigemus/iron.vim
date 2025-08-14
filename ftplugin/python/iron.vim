if index(keys(g:iron_repl_def), "python") == -1
  if !empty($VIRTUAL_ENV)
    let venv_path = $VIRTUAL_ENV
    let python_def = [
      \ "source " . venv_path . "/bin/activate",
      \ "python3",
    \ ]
  else
    let python_def = ["python3"]
  endif

  let g:iron_repl_def["python"] = python_def
endif

function! IronFormat(lines)
  let kwargs = {"exceptions": ["else", "elif", "except", "finally", "#"]}
  let repl_text = iron#core#format(a:lines, kwargs)
  call iron#helpers#debug_log("python", repl_text)
  return repl_text
endfunction
