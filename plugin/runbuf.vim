" TODO: set filetype of input buffer to 'sql.runbuf', and load most of this only
" if runbuf is in the filetype list.


" Key to map for running to command, mapped in normal and insert mode.
let g:runbuf_map = get(g:, 'runbuf_map', '<C-s>')

" Shortcuts for commands; useful if you have longer connection strings or
" the like.
let g:runbuf_commands = get(g:, 'runbuf_commands', #{})

" List of commands to run when creating the output window.
let g:runbuf_output = get(g:, 'runbuf_output', ['below new', 'resize 15', 'setl nowrap'])

" Directory to place the input files. Will be created.
let g:runbuf_dir = get(g:, 'runbuf_dir', expand($XDG_CACHE_HOME isnot# '' ? $XDG_CACHE_HOME : '~/.cache/runbuf'))

" Extensions for the input files, so filetypes work correctly and your edit
" history for Python and psql are separate.
" The filename will be <command>.<ext>
" TODO: merge with existing dict?
let g:runbuf_extensions = get(g:, 'runbuf_extensions', #{
	\ psql:    'sql',
	\ sqlite3: 'sql',
	\ mysql:   'sql',
	\ python:  'py',
	\ ruby:    'rb'
\ })


fun! s:runbuf(cmd) abort
	let cmd = a:cmd
	if get(g:runbuf_commands, cmd, '') isnot ''
		let cmd = g:runbuf_commands[cmd]
	endif

	call mkdir(g:runbuf_dir, 'p')
	exe ':e ' .. fnameescape(s:file(cmd))
	let b:cmd = cmd

	call s:create_output()
	exe 'nnoremap <buffer> ' .. g:runbuf_map .. '      :call <SID>send()<CR>'
	exe 'inoremap <buffer> ' .. g:runbuf_map .. ' <C-o>:call <SID>send()<CR>'
endfun

fun! s:file(cmd) abort
	let w = split(a:cmd, ' ')[0]
	return printf('%s/%s.%s', g:runbuf_dir, w, get(g:runbuf_extensions, w, ''))
endfun

fun s:create_output() abort
	if bufwinnr('runbuf-output') isnot -1
		return
	endif

	" Create output window.
	for c in g:runbuf_output
		exe c
	endfor
	silent setl buftype=nofile
	silent file runbuf-output
	wincmd w
endfun

fun! s:send() abort
	echo b:cmd
	let out = systemlist(b:cmd, bufnr(''))

	call s:create_output()
	let b = bufnr('runbuf-output')
	silent call deletebufline(b, 1, '$')
	silent call setbufline(b, 1, out)

	if v:shell_error
		echohl Error
		echom b:cmd .. ': exit ' .. v:shell_error
		echohl None
	endif
endfun

command -nargs=1 Runbuf :call s:runbuf(<f-args>)
