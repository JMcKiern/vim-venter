let s:save_cpo = &cpo
set cpo&vim

if exists("g:loaded_venter")
	finish
endif
let g:loaded_venter = 1

if !exists("g:venter_disable_vertsplit")
	let g:venter_disable_vertsplit = v:false
endif

if !exists(":Venter")
	command -nargs=0 Venter :call venter#Venter()
endif

let &cpo = s:save_cpo
unlet s:save_cpo
