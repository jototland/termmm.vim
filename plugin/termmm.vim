if exists("g:loaded_termmm")
    " finish
endif
let g:loaded_termmm = 1

if !has('nvim') && !has('terminal')
    finish
endif

command! -nargs=? Tshow call termmm#show(<f-args>)
command! -nargs=? Ttoggle call termmm#toggle(<f-args>)
command! -nargs=? Tkill call termmm#kill(<f-args>)
command! -nargs=? Trestart call termmm#restart(<f-args>)
command! -nargs=0 Thide call termmm#hide()
command! -nargs=0 Tfinish call termmm#finish(bufnr())
