if exists("g:autoloaded_toggleterm")
    finish
endif
let g:autoloaded_toggleterm = 1

if !has('nvim') && !has('terminal')
    finish
endif

function! toggleterm#show(...) abort
    call s:showOrToggle(0, a:0 ? a:1 : 'unnamed')
endfunction

function! toggleterm#toggle(...) abort
    call s:showOrToggle(1, a:0 ? a:1 : 'unnamed')
endfunction

function! toggleterm#register(name, cmd, ...)
    let nofocus = a:0 ? a:1 : 0
    let s:cmd[a:name] = a:cmd
    let s:nofocus[a:name] = nofocus
endfunction

function! toggleterm#unregister(name)
    silent! unlet s:cmd[a:name]
    silent! unlet s:nofocus[a:name]
endfunction

let s:cmd = {}
let s:nofocus = {}

function! toggleterm#hide() abort
    let origWinId = win_getid()
    let i = winnr('$')
    while i > 0
        execute i . 'wincmd w'
        if &filetype ==# 'toggleterm'
            hide
        endif
        let i -= 1
    endwhile
    call win_gotoid(origWinId)
endfunction

function! s:splittype() abort
    if exists("g:toggleterm_splittype")
        if g:toggleterm_splittype =~
            \ '\%(\<\%(' .
            \ 'aboveleft|leftabove|abo|lefta' .
            \ '|topleft|to' .
            \ '|belowright|rightbelow|bel|rightb' .
            \ '|botright|bot' .
            \ '|vertical|vert' .
            \ '|tab' .
            \ '\)\>\s*\)*'
            return g:toggleterm_splittype . ' '
        else
            echom "Invalid value for g:toggleterm_splittype: '" .
                \ g:toggleterm_splittype . "'"
            return 'belowright '
        endif
    else
        return 'belowright '
    endif
endfunction

function! s:vertical() abort
    if s:splittype() =~# '\<vertical\>'
        return 'vertical '
    else
        return ''
    endif
endfunction

function! s:size() abort
    if exists("g:toggleterm_size")
        if type(g:toggleterm_size) ==# v:t_number
            return g:toggleterm_size
        else
            echom "Invalid value for g:toggleterm_size: " .
                \ g:toggleterm_size
            return s:vertical() ==# '' ? 10 : 80
        endif
    else
        return s:vertical() ==# '' ? 10 : 80
    endif
endfunction

function! s:cmd(name) abort
    if exists("s:cmd[a:name]")
        return s:cmd[a:name]
    else
        return &shell
    endif
endfunction

function! s:nofocus(name) abort
    if exists("s:nofocus[a:name]")
        return s:nofocus[a:name]
    else
        return 0
    endif
endfunction

function! s:showOrToggle(toggle, name)
    let origWinId = win_getid()
    let tbuf = bufnr('toggleterm://' . a:name)
    let windowIDs = win_findbuf(tbuf)
    if len(windowIDs) > 0
        if a:toggle
            for id in windowIDs
                execute win_id2win(id) . 'wincmd c'
            endfor
        endif
        return
    endif
    execute s:splittype() . s:size() . 'split'
    if s:vertical()
        setlocal winfixwidth
    else
        setlocal winfixheight
    endif
    setlocal nonumber
    setlocal signcolumn=
    if tbuf !=# -1
        execute tbuf . 'buffer'
    else
        if has("nvim")
            execute 'terminal ' s:cmd(a:name)
        else
            execute 'terminal ++close ++norestore ++kill=term ++curwin ' . 
                \ s:cmd(a:name)
        endif
        setlocal filetype=toggleterm
        execute 'file toggleterm://' . a:name
    endif
    if s:nofocus(a:name)
        call win_gotoid(origWinId)
    endif
endfunction
