runbuf.vim makes it easy to run shell commands and display the output.

The original use case I wrote this for is for running SQL queries with
PostgreSQL; you can use `\e` in `psql` to load `$EDITOR`, but it's a bit
cumbersome. After running `:Runbuf psql dbname` you can write your queries and
send it to `psql` with `<C-s>`. This will load the results in a split and keeps
the query you've written.

I then realized that this will actually work well for `python` or any other CLI
that accepts stdin as well, so I renamed it from `sql.vim` to `runbuf.vim` :-)

---

Start it with `:Runbuf <cmd>`, for example `:Runbuf psql mydb` or `:Runbuf
python`. This will always edit the same file, which is useful since Vim's undo
history will give you an edit history on this. The file directory is determined
with `g:runbuf_dir`, and the filename's extension based on the first word in
the comnad from the `g:runbuf_extensions` dict.

Then hit `<C-s>` in normal or insert mode to run the command and get the output.

runbuf.vim is pretty agnostic, it sends the input buffer to a command and
displays the output; some examples:

    :Runbuf psql dbname
    :Runbuf psql -h somehost.example.com dbname
    :Runbuf psql --expanded dbname
    :Runbuf sqlite3 file.sqlite
    :Runbuf python

---

Options with their defaults:

    " Key to map for running to command, mapped in normal and insert mode.
    let g:runbuf_map = '<C-s>'

    " Shortcuts for commands; useful if you have longer connection strings or
    the like.
    let g:runbuf_commands = #{}

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
        \ python:  'py',
        \ ruby:    'rb'
    \ }
