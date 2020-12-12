if exists("g:autoloaded_termmm")
    finish
endif
let g:autoloaded_termmm = 1

if !has('nvim') && !has('terminal')
    finish
endif

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
        augroup termmm_waitfinished
            autocmd! * <buffer>
            autocmd BufUnload <buffer> call s:onUnloadBuffer(expand("<afile>"))
        augroup END
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
    let origHidden = getbufvar(a:buffer, '&hidden')
    call setbufvar(a:buffer, '&hidden', 1)
    let winList = win_findbuf(a:buffer)
    tabnew
    let newbuf = bufnr()
    tabclose
    let pos = {}
    for win in winList
        call win_execute(win, 'let pos[win] = getcurpos()')
        call win_execute(win, 'noautocmd ' . newbuf . 'buffer')
    endfor
    execute a:buffer . 'bunload'
    for win in winList
        call win_execute(win, a:buffer . 'buffer')
        call win_execute(win, 'call setpos(".", pos[win])')
    endfor
    execute newbuf . 'bwipe'
    call setbufvar(a:buffer, '&hidden', origHidden)
endfunction

function! s:onUnloadBuffer(buffer) abort
    if has("nvim")
        let nvrbufs = getbufvar(a:buffer, 'nvr', [])
        for client in nvrbufs
            silent! call rpcnotify(client, 'Exit', 1)
        endfor
    elseif has('clientserver')
        " do nothing
    else 
        " Vim8 terminal api
        if bufexists(a:buffer)
            let waitlist = getbufvar(a:buffer, 'termmm_wait', [])
            for elem in waitlist
                call term_sendkeys(elem['buffer'], "\n" . elem['token'] . "\n")
            endfor
            silent! call remove(getbufvar(a:buffer, ''), 'termmm_wait')
        endif
    endif
endfunction

function! s:name(name) abort
    return substitute(a:name, '^termmm://\(.*\)$', '\1', '')
endfunction

function! s:tname(name) abort
    if a:name =~# '^termmm://.*$'
        return a:name
    else
        return 'termmm://' . a:name
    endif
endfunction

function! s:tbuf(name) abort
    return bufnr(s:tname(a:name))
endfunction

function! termmm#show(name) abort
    let oldWinId = win_getid()
    let tbuf = s:tbuf(a:name)
    let windowIDs = win_findbuf(tbuf)
    if len(windowIDs) > 0
        call win_gotoid(windowIDs[1])
    else
        execute s:splitcmd()
        if tbuf !=# -1
            execute tbuf . 'buffer'
        else
            call termmm#start(a:name)
        endif
    endif
    if s:nofocus(a:name)
        call win_gotoid(oldWinId)
    endif
endfunction

function! termmm#hide(name) abort
    let tbuf = s:tbuf(a:name)
    let windowIds = win_findbuf(tbuf)
    for win in windowIds
        call win_execute(win, 'wincmd c')
    endfor
endfunction

function! termmm#hideAll() abort
    let tnames = termmm#enumerate()
    for tname in tnames
        call termmm#hide(tname)
    endfor
endfunction

function! termmm#visible(name) abort
    return len(win_findbuf(s:tbuf(a:name))) > 0
endfunction

function! termmm#exists(name) abort
    let tname = s:tname(a:name)
    let buffer = s:tbuf(tname)
    return buffer !=# -1 &&
        \ getbufvar(buffer, '&buftype') ==# 'terminal' &&
        \ bufname(buffer) ==# tname
endfunction

function! termmm#toggle(name) abort
    if termmm#visible(a:name)
        call termmm#hide(a:name)
    else
        call termmm#show(a:name)
    endif
endfunction

function! termmm#enumerate() abort
    let buffers = filter(range(1, bufnr('$')), 'bufexists(v:val)')
    call filter(buffers, 'bufname(v:val) =~# "^termmm://.*$"')
    call map(buffers, 's:name(bufname(v:val))')
    return buffers
endfunction

function! termmm#ls() abort
    for buf in termmm#enumerate()
        echo buf
    endfor
endfunction

let s:termmm_path=expand('<sfile>:p:h:h') 
let s:pathsep = has("win32") ? '\' : '/'
let s:pathlistsep = has("win32") ? ';' : ':'

let s:orig_path = $PATH
let s:new_path = s:termmm_path . s:pathsep . 'bin' . s:pathlistsep . s:orig_path

let $TERMMM_PATH=s:termmm_path

if has('clientserver')
    let $TERMMM_VIMPATH=v:progpath
endif

function! s:getgitbash()
    if exists("g:termmm_bash")
        return g:termmm_bash
    else
        let git=exepath("git.exe")
        let gitbash = fnamemodify(git, ':p:h:h') . '\bin\bash.exe'
        if executable(gitbash)
            return gitbash
        else
            return 'C:\Program Files\Git\bin\bash.exe'
        endif
    endif
endfunction
let $TERMMM_BASH=has('win32') ? s:getgitbash() : 'bash'

function! termmm#start(name) abort
    if termmm#exists(a:name)
        call s:errmsg('termmm ' . a:name . ' already exists')
        return
    endif
    try
        let $PATH=s:new_path
        if has("nvim")
            execute 'terminal ' s:cmd(a:name)
            execute 'file! ' . s:tname(a:name)
        else
            call term_start(s:cmd(a:name), {'term_name': s:tname(a:name),
            \ 'curwin': 1, 'norestore': 1, 'term_kill': 'term',
            \ 'term_finish': 'close'})
        endif
    catch
        call s:errmsg('An exception occured running the command: ' . s:cmd(a:name))
        return
    finally
        let $PATH=s:orig_path
    endtry
    setlocal filetype=termmm
    setlocal nonumber
    setlocal signcolumn=
    setlocal nobuflisted
endfunction

function! termmm#kill(name) abort
    let tbuf = s:tbuf(a:name)
    if tbuf ==# -1
        call s:errmsg('termmmm ' . a:name . ' doesn''t exist')
        return
    else
        execute tbuf . 'bwipe!'
    endif
endfunction

function! termmm#restart(name) abort
    if termmm#exists(a:name)
        call call('termmm#kill', a:name)
    endif
    call call('termmm#start', a:name)
endfunction

function! s:splitcmd() abort
    if exists("g:termmm_splitcmd")
        return g:termmm_splitcmd
    else
        return 'belowright split'
    endif
endfunction

function! s:cmd(name) abort
    let name = s:name(a:name)
    if exists("g:termmm_config[name]['cmd']")
        return g:termmm_config[name]['cmd']
    else
        return &shell
    endif
endfunction

function! s:nofocus(name) abort
    let name = s:name(a:name)
    if exists("g:termmm_config[name]['nofocus']")
        return g:termmm_config[name]['nofocus']
    else
        return 0
    endif
endfunction

function! termmm#complete(arglead, cmdline, cursorpos) abort
    let compl = keys(get(g:, 'termmm_config', {}))
    call extend(compl, termmm#enumerate())
    call sort(compl)
    call uniq(compl)
    return filter(compl, "v:val =~# '^" . a:arglead . "'")
endfunction

function s:quote(str) abort
    return "'" . substitute(a:str, "'", "''", 'g') . "'"
endfunction

function! s:errmsg(msg) abort
    echohl ErrorMsg
    execute 'echomsg ' . s:quote(a:msg)
    echohl None
endfunction
