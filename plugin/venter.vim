let s:save_cpo = &cpo
set cpo&vim

if exists("g:loaded_venter")
	finish
endif
let g:loaded_venter = 1

if !exists("g:venter_disable_vertsplit")
	let g:venter_disable_vertsplit = v:false
endif

if !exists("g:venter_close_tab_if_empty")
	let g:venter_close_tab_if_empty = v:true
endif

if !exists(":Venter")
	command -nargs=0 Venter :call venter#Venter()
endif

if !exists(":VenterToggle")
	command -nargs=0 VenterToggle :call venter#VenterToggle()
endif

let &cpo = s:save_cpo
unlet s:save_cpo
