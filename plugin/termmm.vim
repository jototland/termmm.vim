if exists("g:loaded_termmm")
    finish
endif
let g:loaded_termmm = 1

if !has('nvim') && !has('terminal')
    finish
endif

command! -nargs=1 -complete=customlist,termmm#complete Tshow call termmm#show(<f-args>)
command! -nargs=1 -complete=customlist,termmm#complete Thide call termmm#hide(<f-args>)
command! -nargs=1 -complete=customlist,termmm#complete Ttoggle call termmm#toggle(<f-args>)

command! -nargs=0 Tls call termmm#ls()
command! -nargs=0 ThideAll call termmm#hideAll()

command! -nargs=1 -complete=customlist,termmm#complete Tstart call termmm#start(<f-args>)
command! -nargs=1 -complete=customlist,termmm#complete Tkill call termmm#kill(<f-args>)
command! -nargs=1 -complete=customlist,termmm#complete Trestart call termmm#restart(<f-args>)

command! -nargs=0 Tfinish call termmm#finish(bufnr())

augroup termmm_readbuffer
    autocmd! *
    autocmd BufReadCmd termmm://* ++nested call s:on_BufReadCmd(expand('<amatch>'))
augroup END

function! s:on_BufReadCmd(name)
    let alt = @#
    setlocal bufhidden=wipe buftype=nofile nobuflisted
    call termmm#start(a:name)
    if has('nvim')
        bwipe #
    else
    endif
    let @# = alt
endfunction
