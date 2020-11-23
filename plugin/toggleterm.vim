if exists("g:loaded_toggleterm")
    finish
endif
let g:loaded_toggleterm = 1

if !has('nvim') && !has('terminal')
    finish
endif

command! -nargs=? ShowTerm call toggleterm#show(<f-args>)
command! -nargs=? ToggleTerm call toggleterm#toggle(<f-args>)
command! -nargs=0 HideTerms call toggleterm#hide()

