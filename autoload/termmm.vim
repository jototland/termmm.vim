if exists("g:autoloaded_termmm")
    " finish
endif
let g:autoloaded_termmm = 1

if !has('nvim') && !has('terminal')
    finish
endif

let s:termmm_path=expand('<sfile>:p:h:h')

function! s:getgitbash()
    if exists("g:termmm_bash")
        return g:termmm_bash
    else
        let gitlocation=exepath("git.exe")
        if executable(gitlocation)
            return fnamemodify(gitlocation, ':p:h:h') . '/bin/bash.exe'
        else
            return 'C:\\Program Files\Git\bin\bash.exe'
        endif
    endif
endfunction
execute 'echom "' .  s:getgitbash() . '"'

augroup termmm
    autocmd!
    autocmd BufWritePre * call s:finish(bufnr())
    " autocmd BufUnload * call s:finish(expand("<afile>"))
    autocmd BufHidden * call s:finish(expand("<afile>"))
augroup END

function! Tapi_termmm_open_wait(bufno, arg)
    let file = a:arg[0]
    let token = a:arg[1]
    execute 'aboveleft split ' . file
    let b:termmm_waitingTerminal = a:bufno
    let b:termmm_waitToken = token
endfunction

function! Tapi_termmm_cancel_wait(bufno, arg)
    let bufno = bufnr(a:arg)
    if bufno !=# -1
        call remove(getbufvar(bufno, ''), 'termmm_waitingTerminal')
        call remove(getbufvar(bufno, ''), 'termmm_waitToken')
        execute bufno . 'bunload'
    endif
endfunction

function s:finish(buffer)
    if bufexists(a:buffer)
        let term = getbufvar(a:buffer, "termmm_waitingTerminal", 0)
        let token = getbufvar(a:buffer, "termmm_waitToken", 0)
        if term
            call term_sendkeys(term, "\n" . token . "\n")
            call remove(getbufvar(a:buffer, ''), 'termmm_waitingTerminal')
            call remove(getbufvar(a:buffer, ''), 'termmm_waitToken')
        endif
    endif
endfunction

function! termmm#show(...) abort
    call s:showOrToggle(0, a:0 ? a:1 : 'unnamed')
endfunction

function! termmm#toggle(...) abort
    call s:showOrToggle(1, a:0 ? a:1 : 'unnamed')
endfunction

function! termmm#hide() abort
    let origWinId = win_getid()
    let i = winnr('$')
    while i > 0
        execute i . 'wincmd w'
        if &filetype ==# 'termmm'
            hide
        endif
        let i -= 1
    endwhile
    call win_gotoid(origWinId)
endfunction

function! termmm#kill(...) abort
    let tbuf = bufnr('termmm://' . (a:0 ? a:1 : 'unnamed'))
    if tbuf !=# -1
        execute tbuf . 'bwipe!'
    endif
endfunction

function! termmm#restart(...) abort
    call call('termmm#kill', a:000)
    call call('termmm#show', a:000)
endfunction

function! s:splittype() abort
    if exists("g:termmm_splittype")
        if g:termmm_splittype =~
            \ '\%(\<\%(' .
            \ 'aboveleft|leftabove|abo|lefta' .
            \ '|topleft|to' .
            \ '|belowright|rightbelow|bel|rightb' .
            \ '|botright|bot' .
            \ '|vertical|vert' .
            \ '|tab' .
            \ '\)\>\s*\)*'
            return g:termmm_splittype . ' '
        else
            echom "Invalid value for g:termmm_splittype: '" .
                \ g:termmm_splittype . "'"
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

function! s:cmd(name) abort
    if exists("g:termmm_config[a:name]['cmd']")
        return g:termmm_config[a:name]['cmd']
    else
        return &shell
    endif
endfunction

function! s:nofocus(name) abort
    if exists("g:termmm_config[a:name]['nofocus']")
        return g:termmm_config[a:name]['nofocus']
    else
        return 0
    endif
endfunction

function! s:showOrToggle(toggle, name)
    let origWinId = win_getid()
    let tbuf = bufnr('termmm://' . a:name)
    let windowIDs = win_findbuf(tbuf)
    if len(windowIDs) > 0
        if a:toggle
            for id in windowIDs
                execute win_id2win(id) . 'wincmd c'
            endfor
        endif
        return
    endif
    execute s:splittype() . 'split'
    if tbuf !=# -1
        execute tbuf . 'buffer'
    else
        let oldpath=$PATH
        let $TERMMM_PATH=s:termmm_path
        let $TERMMM_BASH=has('win32') ? s:getgitbash() : 'bash'
        let $PATH=s:termmm_path . '/bin:' . $PATH
        try
            if has("nvim")
                execute 'terminal ' s:cmd(a:name)
            else
                execute 'terminal ++close ++norestore ++kill=term ++curwin ' . 
                    \ s:cmd(a:name)
            endif
        finally
            let $PATH=oldpath
        endtry
        setlocal filetype=termmm
        execute 'file termmm://' . a:name
        setlocal nonumber
        setlocal signcolumn=
    endif
    if s:nofocus(a:name)
        call win_gotoid(origWinId)
    endif
endfunction
