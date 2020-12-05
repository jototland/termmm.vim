if exists("g:autoloaded_termmm")
    " finish
endif
let g:autoloaded_termmm = 1

if !has('nvim') && !has('terminal')
    finish
endif

let s:termmm_path=expand('<sfile>:p:h:h') 
let s:pathsep = has("win32") ? '\' : '/'
let s:pathlistsep = has("win32") ? ';' : ':'

augroup termmm
    autocmd!
    autocmd BufUnload * call termmm#finish(expand("<afile>"))
augroup END

function! Tapi_termmm_open(bufno, arg) abort
    let splitCmd = a:arg[0]
    let waitFinished = a:arg[1]
    let fileToOpen = a:arg[2]
    let token = a:arg[3]
    let alreadyOpen = bufwinnr(bufnr(fileToOpen))
    if alreadyOpen !=# -1
        execute alreadyOpen . 'wincmd w'
    else
        if splitCmd ==# ''
            execute 'edit ' . fileToOpen
        else
            execute splitCmd . ' ' . fileToOpen
        endif
    endif
    if waitFinished ==# 1
        let b:termmm_wait = get(b:, 'termmm_wait', [])
        let b:termmm_wait = add(b:termmm_wait, {'buffer': a:bufno, 'token': token})
    endif
endfunction

function! Tapi_termmm_cancel_wait(tbuf, arg)
    if a:tbuf !=# -1
        let buffers = filter(range(1, bufnr('$')), 'bufexists(v:val)')
        for buf in buffers
            let found = v:false
            let waitlist = getbufvar(buf, 'termmm_wait', [])
            let i = len(waitlist) - 1
            while i >= 0
                if waitlist[i]['buffer'] ==# a:tbuf
                    let found = v:true
                    call remove(waitlist, i)
                endif
                let i -= 1
            endwhile
            if len(waitlist) ==# 0
                silent! call remove(gutbufvar(buf, ''), 'termmm_wait')
                if found
                    execute bufwinnr(buf) . 'hide'
                endif
            endif
        endfor
    endif
endfunction

function! termmm#finish(buffer) abort
    if has("nvim")
        " let nvrbufs = getbufvar(a:buffer, 'nvr', [])
        " for client in nvrbufs
        "     silent! call rpcnotify(client, 'Exit', 1)
        " endfor
    elseif has('clientserver')
        " FIXME: loop: execute buffer . 'bunload'
    else
        if bufexists(a:buffer)
            let waitlist = getbufvar(a:buffer, 'termmm_wait', [])
            for elem in waitlist
                call term_sendkeys(elem['buffer'], "\n" . elem['token'] . "\n")
            endfor
            silent! call remove(getbufvar(a:buffer, ''), 'termmm_wait')
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
        if has('clientserver')
            let $TERMMM_VIMPATH=v:progpath
            let $TERMMM_SERVERNAME=v:servername
        endif
        let $PATH=s:termmm_path . s:pathsep . 'bin' . s:pathlistsep . $PATH
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
        setlocal nobuflisted
    endif
    if s:nofocus(a:name)
        call win_gotoid(origWinId)
    endif
endfunction

function! s:getgitbash()
    if exists("g:termmm_bash")
        return g:termmm_bash
    else
        let gitlocation=exepath("git.exe")
        if executable(gitlocation)
            return fnamemodify(gitlocation, ':p:h:h') . '\bin\bash.exe'
        else
            return 'C:\Program Files\Git\bin\bash.exe'
        endif
    endif
endfunction
