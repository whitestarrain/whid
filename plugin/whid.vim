" in plugin/whid.vim
if exists('g:loaded_whid') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

" command to run our plugin
command! Whid lua require'whid'.whid()

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo


command! Whid lua require'whid'.whid()

" We will link to existing default highlights group instead of setting color by ourselves
" This way it will match user colorsheme.
hi def link WhidHeader      Number
hi def link WhidSubHeader   Identifier

let g:loaded_whid = 1
