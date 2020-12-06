" Key to map for running to command, mapped in normal and insert mode.
let g:runbuf_map = get(g:, 'runbuf_map', '<C-s>')

" Shortcuts for commands; useful if you have longer connection strings or
" the like.
let g:runbuf_commands = extend(#{
	\ go: 'go run %s',
\ }, get(g:, 'runbuf_commands', {}))

" List of commands to run when creating the output window.
let g:runbuf_output = get(g:, 'runbuf_output', ['below new', 'resize 15', 'setl nowrap'])

" Directory to place the input files. Will be created.
let g:runbuf_dir = get(g:, 'runbuf_dir', expand($XDG_CACHE_HOME isnot# '' ? $XDG_CACHE_HOME : '~/.cache/runbuf'))

" Extensions for the input files, so filetypes work correctly and your edit
" history for Python and psql are separate.
" The filename will be <command>.<ext>
let g:runbuf_extensions = extend(#{
	\ psql:    'sql',
	\ sqlite3: 'sql',
	\ mysql:   'sql',
	\ go:      'go',
	\ python:  'py',
	\ ruby:    'rb'
\ }, get(g:, 'runbuf_extensions', {}))

" Resize output buffer.
let g:runbuf_resize = get(g:, 'runbuf_resize', 1)


fun! s:runbuf(cmd) abort
	let cmd = a:cmd
	if get(g:runbuf_commands, cmd, '') isnot ''
		let cmd = g:runbuf_commands[cmd]
	endif

	call mkdir(g:runbuf_dir, 'p')

	if bufexists(s:file(cmd))
		echohl Error | echom printf('Buffer for %s already exists', s:file(cmd)) | echohl None
		return
	endif

	exe 'edit ' .. fnameescape(s:file(cmd))
	set ft+=.runbuf
	let b:cmd = cmd
	let b:output = printf('runbuf-output-%s-%s', fnamemodify(bufname(''), ':e'), localtime())

	call s:create_output()

	exe 'nnoremap <buffer> ' .. g:runbuf_map .. '      :call <SID>send()<CR>'
	exe 'inoremap <buffer> ' .. g:runbuf_map .. ' <C-o>:call <SID>send()<CR>'
endfun

fun! s:file(cmd) abort
	let w = split(a:cmd, ' ')[0]
	return printf('%s/%s.%s', g:runbuf_dir, w, get(g:runbuf_extensions, w, ''))
endfun

fun s:create_output() abort
	let o = b:output
	if bufwinnr(o) isnot -1
		return
	endif

	" Create output window.
	for c in g:runbuf_output
		exe c
	endfor
	silent setl buftype=nofile noswapfile nomodifiable
	silent exe 'file ' .. o
	wincmd w
endfun

fun! s:send() abort
	echo b:cmd
	if stridx(b:cmd, '%s') > -1
		silent w
		let out = systemlist(printf(b:cmd, shellescape(fnamemodify(bufname(''), ':p'))))
	else
		let out = systemlist(b:cmd, bufnr(''))
	endif

	call s:create_output()
	let b = bufnr(b:output)
	silent call setbufvar(b, '&modifiable', '1')
	silent call deletebufline(b, 1, '$')
	silent call setbufline(b, 1, out)
	silent call setbufvar(b, '&modifiable', '0')
	silent call win_execute(win_getid(b), 'normal! gg')

	" TODO: also support width?
	if g:runbuf_resize
		let ui_chrome = &cmdheight + 2
		if &showtabline is 2 || (&showtabline is 1 && len(gettabinfo()) > 1)
			let ui_chrome += 1
		endif
		exe b .. 'resize ' .. min([
			\ &lines - line('$') - ui_chrome,
			\ getbufinfo(b)[0]['linecount']])
	endif

	if v:shell_error
		echohl Error | echom b:cmd .. ': exit ' .. v:shell_error | echohl None
	endif
endfun

fun! s:complete(lead, cmdline, cursor) abort
	return join(sort(keys(g:runbuf_commands)), "\n")
endfun

command -nargs=1 -complete=custom,s:complete Runbuf :call s:runbuf(<f-args>)
