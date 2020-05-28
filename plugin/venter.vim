let s:save_cpo = &cpo
set cpo&vim

if exists("g:loaded_venter")
	finish
endif
let g:loaded_venter = 1

if !exists("g:venter_open_winids")
	let g:venter_open_winids = {}
endif

if !exists("g:venter_disable_vertsplit")
	let g:venter_disable_vertsplit = v:false
endif

if !exists(":Venter")
	command -nargs=0 Venter :call Venter()
endif
if !exists(":VenterClose")
	command -nargs=0 VenterClose :call VenterClose()
endif
if !exists(":VenterResize")
	command -nargs=0 VenterResize :call s:ResizeWindows()
endif

function! Venter()
	if exists("t:venter_tabid") && has_key(g:venter_open_winids, t:venter_tabid)
		return
	endif
	if exists("g:venter_disable_vertsplit") && g:venter_disable_vertsplit
		" Remove and hide vertical splitter
		set fillchars+=vert:\ 
		if has("gui_running")
			highlight VertSplit guifg=bg guibg=bg
		else
			highlight VertSplit ctermfg=bg ctermbg=bg
		endif
	endif

	let l:left_winid = s:CreateWindow('topleft')
	let l:right_winid = s:CreateWindow('botright')
	let t:venter_tabid = len(g:venter_open_winids) > 0 ? max(keys(g:venter_open_winids)) + 1 : 1
	execute 'let g:venter_open_winids.'.t:venter_tabid.' = [l:left_winid, l:right_winid]'

	if len(g:venter_open_winids) == 1
		augroup venter
			autocmd VimResized,TabEnter,WinEnter * call s:ResizeWindows()
			autocmd SafeState * call s:DisableStatuslines()
		augroup END
	endif
	call s:ResizeWindows()
endfunction

function! VenterClose()
	if exists("t:venter_tabid") && has_key(g:venter_open_winids, t:venter_tabid)
		execute 'let l:winids = deepcopy(g:venter_open_winids.'.t:venter_tabid.')'
		for idx in range(0, len(l:winids)-1)
			let l:winnr = win_id2win(l:winids[idx])
			if l:winnr
				execute l:winnr.'wincmd c'
			endif
		endfor
		execute 'unlet g:venter_open_winids.'.t:venter_tabid
		unlet t:venter_tabid
	endif

	call s:CheckWinIds()
endfunction

function! s:CheckWinIds()
	" Check the winids for padding windows in the current tab - remove if no longer valid
	if exists("t:venter_tabid") && has_key(g:venter_open_winids, t:venter_tabid)
		execute 'let l:winids = deepcopy(g:venter_open_winids.'.t:venter_tabid.')'
		for idx in range(0, len(l:winids)-1)
			let l:winnr = win_id2win(l:winids[idx])
			if !l:winnr
				execute 'call remove(g:venter_open_winids.'.t:venter_tabid.', '.idx.')'
			endif
		endfor
	endif

	" If no padding windows in tab, remove tab from dict
	if exists("t:venter_tabid") && has_key(g:venter_open_winids, t:venter_tabid)
		execute 'let l:numwin = len(g:venter_open_winids.'.t:venter_tabid.')'
		if l:numwin == 0
			execute 'unlet g:venter_open_winids.'.t:venter_tabid
		endif
	endif

	" If no padding windows in any tab, remove autocmds
	if len(g:venter_open_winids) == 0
		augroup venter
			au!
		augroup END
	endif

	" If there are only padding windows left, close tab and open a new one
	if exists("t:venter_tabid") && has_key(g:venter_open_winids, t:venter_tabid)
		execute 'let l:numwin = len(g:venter_open_winids.'.t:venter_tabid.')'
		execute 'let l:winids = deepcopy(g:venter_open_winids.'.t:venter_tabid.')'
		if winnr('$') == l:numwin
			execute 'unlet g:venter_open_winids.'.t:venter_tabid
			tabnew
			tabclose -1
		endif
	endif
endfunction

function! s:CreateWindow(pos)
	" Create a padding window at specified position
	" Returns the winid
	let l:prevbuf = bufnr()
	execute 'vertical '.a:pos.' new'

	" Add empty lines
	call append(0, map(range(0, &lines), '""'))
	normal! gg

	" Buffer settings
	set nonumber norelativenumber nocursorline nocursorcolumn
	setlocal buftype=nofile bufhidden=wipe nobuflisted
	" setlocal buftype=nofile bufhidden=wipe nomodifiable nobuflisted

	" Return to previous window if padding window selected
	autocmd WinEnter <buffer> execute winnr('#').' wincmd w'

	let l:winid=win_getid()
	execute bufwinnr(l:prevbuf).'wincmd w'
	return l:winid
endfunction

function! s:ReturnToPrev()
	echom 'winnr() '.winnr()
	echom 'winnr(''#'') '.winnr('#')
	execute winnr('#').' wincmd w'
endfunction

function! s:DisableStatuslines()
	call s:CheckWinIds()
	let l:winids = s:GetCurTabWinIds()
	for l:winid in l:winids
		let l:winnr = win_id2win(l:winid)
		if l:winnr
			call setwinvar(l:winnr, '&statusline', '%#NORMAL#')
		endif
	endfor
endfunction

function! s:ResizeWindows()
	call s:CheckWinIds()
	let l:winids = s:GetCurTabWinIds()
	for l:winid in l:winids
		let l:winnr = win_id2win(l:winid)
		if l:winnr
			execute 'vertical '.l:winnr.'resize '. (exists("g:venter_width") ? g:venter_width : &columns/4)
			let l:buflines = line('$', l:winid)
			let l:diff = &lines - l:buflines
			if l:diff > 0
				call appendbufline(winbufnr(l:winnr), l:buflines, map(range(0, l:diff), '""'))
			endif
		endif
	endfor
endfunction

function! s:GetCurTabWinIds()
	if exists("t:venter_tabid") && has_key(g:venter_open_winids, t:venter_tabid)
		execute 'let l:winids = deepcopy(g:venter_open_winids.'.t:venter_tabid.')'
		return l:winids
	endif
	return []
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
