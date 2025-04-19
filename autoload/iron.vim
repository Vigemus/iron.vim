function! iron#setup()
  let named_maps = {
    \ "toggle_repl": ["n", ":IronRepl<CR>"],
    \ "repl_restart": ["n", ":IronRestart<CR>"],
    \ "repl_kill": ["n", ":IronKill<CR>"],
    \ "send_line": [
      \ "n",
      \ ":silent! normal! V<CR>:<C-u>call iron#core#send(getline(\"'<\", \"'>\"))<CR>",
      \ ],
    \ "send_visual": [
      \ "v",
      \ ":<C-u>call iron#core#send(getline(\"'<\", \"'>\"))<CR>",
      \ ],
    \ "send_paragraph": [
      \ "n",
      \ ":silent! normal! vip<CR>:<C-u>call iron#core#send(getline(\"'<\", \"'>\"))<CR>",
      \ ],
    \ "send_until_cursor": [
      \ "n",
      \ ":silent! normal! mAVgg<CR>:<C-u>call iron#core#send(getline(\"'<\", \"'>\"))<CR>`A",
      \ ],
    \ "send_file": [
      \ "n",
      \ ":silent! normal! mAggvG<CR>:<C-u>call iron#core#send(getline(\"'<\", \"'>\"))<CR>`A",
      \ ],
    \ "send_cancel": [
      \ "n",
      \ ":call iron#core#send(\"\\x03\")<CR>",
      \ ],
    \ "send_blank_line": [
      \ "n",
      \ ":call iron#core#send(\"\\r\")<CR>",
      \ ],
    \ "clear": [
      \ "n",
      \ ":call iron#core#send(nr2char(12))<CR>",
      \ ],
    \ }

  command! IronRepl call iron#core#toggle_repl('toggle')
  command! IronKill call iron#core#kill_repl()
  command! IronRestart call iron#core#restart_repl()

  let g:iron_repl_meta = {}  " memory for active repls.

  if !exists("g:iron_repl_def")
    let g:iron_repl_def = {}  " defaults are set in ftplugin
  endif

  if !exists("g:iron_repl_open_cmd")
    let g:iron_repl_open_cmd = {
      \ 'vertical': iron#view#split('vertical rightbelow', 0.4),
    \}
  endif

  if !exists("g:iron_repl_debug_log")
    let g:iron_repl_debug_log = 0
  endif

  if !exists("g:iron_term_wait")
    let g:iron_term_wait = 0
  endif
  
  if len(keys(g:iron_repl_open_cmd)) > 1
    for key in keys(g:iron_repl_open_cmd)
      if index(keys(g:iron_keymaps), "toggle_" . key) == -1
        let msg = "ERROR: The repl_open_cmd " . key " does not have a keymap defined"
        let msg = msg . " in g:iron_keymaps"
        throw msg
      endif
    endfor
  endif

  for key in keys(g:iron_repl_open_cmd)
    let toggle_command = ":call iron#core#toggle_repl('". key . "')<CR>"
    let named_maps["toggle_" . key] = ["n", toggle_command]
  endfor

  for named_map in keys(g:iron_keymaps)
    let mode = named_maps[named_map][0]
    let key = g:iron_keymaps[named_map]
    let key_command = named_maps[named_map][1]
    execute mode . "noremap " . key . " " . key_command
  endfor
endfunction
