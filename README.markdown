runbuf.vim makes it easy to run the contents of a buffer in psql, python, bash,
etc. and display the output.

This [little demo video](http://tmp.arp242.net/runbuf-demo.mp4) is probably
clearer than any text description.

The original use case I wrote this for is for running SQL queries with
PostgreSQL; you can use `\e` in `psql` to load `$EDITOR`, but it's a bit
cumbersome. After running `:Runbuf psql dbname` you can write your queries and
send it to `psql` with `<C-s>`. This will load the results in a split and keeps
the query you've written.

I realized that this will also work well for `python` or other shells that
accept stdin, so I renamed it from `sql.vim` to `runbuf.vim` :-) It's a pretty
simple plugin, but sped up my PostgreSQL testing workflow by quite a bit.

Usage
-----

Start it with `:Runbuf <cmd>`, for example `:Runbuf psql mydb` or `:Runbuf
python`. This will load a file in `~/.cache/runbuf`, which is the same file for
every command. This is useful since Vim's undo history will give you a kind of
edit history.

The file directory is determined with `g:runbuf_dir`, and the filename's
extension based on the first word in the command from the `g:runbuf_extensions`
dict.

If the command contains a `%s` then this will be replaced with the path of the
input file; for most things you don't need this as many interpreters will read
from stdin, but some compilers (e.g. `go run`) don't.

Hit `<C-s>` in normal or insert mode to run the command and get the output.

Note: many terminals eat `<C-s>` and will stop the terminal output (`<C-q>` to
resume); you probably want to disable this in your shell config (`setopt
noflowcontrol` in zsh; or `stty -ixon quit undef`).

Some examples:

    :Runbuf psql dbname
    :Runbuf python
    :Runbuf sqlite3 file.sqlite

    " Any shell command will do, so you can pass output options and the like.
    :Runbuf psql --expanded -h somehost.example.com dbname

Settings
--------

All settings with their defaults values.

    " Key to map for running to command, mapped in normal and insert mode.
    let g:runbuf_map = '<C-s>'

    " Shortcuts for commands; useful if you have longer connection strings or
    " the like.
    let g:runbuf_commands = #{
        \ go: 'go run %s',
    \ }

    " List of commands to run when creating the output window.
    let g:runbuf_output = ['below new', 'resize 15', 'setl nowrap']

    " Directory to place the input files. Will be created.
    let g:runbuf_dir = expand($XDG_CACHE_HOME isnot# '' ? $XDG_CACHE_HOME : '~/.cache/runbuf')

    " Extensions for the input files, so filetypes work correctly and your edit
    " history for Python and psql are separate.
    " The filename will be <command>.<ext>
    let g:runbuf_extensions = #{
        \ psql:    'sql',
        \ sqlite3: 'sql',
        \ mysql:   'sql',
        \ go:      'go',
        \ python:  'py',
        \ ruby:    'rb'
    \ }

    " Resize output buffer.
    let g:runbuf_resize = get(g:, 'runbuf_resize', 1)

Protips
-------

You can scroll the output buffer without leaving the input window with some
additional keybinds, for example to have `<C-j>` and `<C-k>` scroll by 3 lines:

    augroup my-runbuf
        au!
        au Filetype *.runbuf
            \  nnoremap <buffer> <C-j> :echo win_execute(win_getid(bufnr(b:output)), "normal! 3\<lt>C-e>")<CR>
            \| nnoremap <buffer> <C-k> :echo win_execute(win_getid(bufnr(b:output)), "normal! 3\<lt>C-y>")<CR>
    augroup end

`.runbuf` is appended to the `filetype` of the input buffer, so you can hook in
other things here as well.

---

You can use `+Runbuf` to start things a bit faster; for example:

    $ vim '+Runbuf gc'

Where `gc` is a shortcut to connect to my PostgreSQL database defined in
`g:runbuf_commands`.

---

Some PostgreSQL specific-things:

- If you're using PostgreSQL performance testing on indexes and the like then
  you can use something like:

      begin;
          drop index maybe_bad;
          create index maybe_better [..];

          explain analyze
              select [..]
      rollback;

  This won't work for MariaDB (as for as I know), but PostgreSQL is cool with
  it, and it's an easy way to test out some stuff while keeping your base tables
  intact.

- Since stuff is run through the `psql` CLI, special commands such as `\x` and
  `\d` will work just fine. You can also configure `psql` from `~/.psqlrc` this
  is what I have:

      \set QUIET
      \pset linestyle unicode
      \pset footer off
      \pset null 'NULL'
      \timing on

  There are also flags for `psql` to set this (and other things). See `psql(1)`
  for docs on all of this.
