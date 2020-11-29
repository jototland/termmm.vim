termmm
---
quick toggling of vim/neovim terminals

Introduction
---

This plugin contains contains mappings and commands to quickly toggle terminal
windows of different names and commands.

The actual name of the terminal will be 'termmm://{name}'.
The filetype will be 'termmm'

`Ttoggle [{name}]`
`Tshow [{name}]`
`Thide`

Ttoggle toggles visibility of terminal {name}.
Tshow ensures visibility of terminal {name}.
Thide hides all terminals managed by termmm.

Configuration
---

`g:termmm_config`

This configuration variable allows you to store configuration for certain named
termmms. Is is a dictionary (by name), each value being a dictionary
with configuration settings for the termmmof that name.

Example configuration:

    let g:termmm_config = get(g:, 'termmm_config', {})
    let g:termmm_config['python'] = {'cmd':'python3', 'nofocus':1}
    let g:termmm_config['R'] = {'cmd':'R --vanilla --quiet', 'nofocus':1}


The 'cmd' key stores the command to be run whenever you start that terminal.

If the 'nofocus' key is true, the termmm will not automatically get focus,
when it is visible.

`g:termmm_splittype`

The command modifiers to use when splitting the window to show a terminal.
Valid values is either an empty string, or a space separated string consisting
of one or more of the following words/vim commands (colons not necessary):
|:aboveleft|, |:topleft|, |:belowright|, |:botright|, |:vertical|. 

Default value: 'belowright'
