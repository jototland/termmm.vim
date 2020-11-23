toggleterm
---
quick toggling of vim/neovim terminals

Introduction
---

This plugin contains contains mappings and commands to quickly toggle terminal
windows of different names and commands.

The actual name of the terminal will be 'toggleterm://{name}'.
The filetype will be 'toggleterm'

`ToggleTerm [{name}]`
`ShowTerm [{name}]`
`HideTerms`

ToggleTerm toggles visibility of terminal {name}.
ShowTerm ensures visibility of terminal {name}.
HideTerms hides all terminals managed by toggleterm.

Configuration
---

`toggleterm#register({name}, {cmd}, [{nofocus}])`
---

Registers a cmd to run, whenever ToggleTerm {name} is called.

If the optional argument {nofocus} is true, the terminal will not be focused
when it is shown.

`toggleterm#unregister(name)`
---

Unregister 'name', so ToggleTerm or ShowTerm doesn't do anything special.

`g:toggleterm_splittype`
---

The command modifiers to use when splitting the window to show a terminal.
Valid values is either an empty string, or a space separated string consisting
of one or more of the following words/vim commands (colons not necessary):
|:aboveleft|, |:topleft|, |:belowright|, |:botright|, |:vertical|. 

Default value: 'belowright'

`g:toggleterm_size`
---

The height of the toggleterm-window. Or if |g:toggleterm_splittype| contains the
word |vertical|, the width of the toggleterm-window. 

Default value: 10 for splits and 80 for vsplits.