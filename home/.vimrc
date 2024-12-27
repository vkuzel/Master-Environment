syntax on

execute "set <xUp>=\e[1;*A"
execute "set <xDown>=\e[1;*B"
execute "set <xRight>=\e[1;*C"
execute "set <xLeft>=\e[1;*D"

imap <C-Backspace> <C-W>
imap <C-Del> X<Esc>lbce

