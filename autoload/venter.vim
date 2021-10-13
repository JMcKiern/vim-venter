let s:save_cpo = &cpo
set cpo&vim

if !exists("s:open_winids")
	let s:open_winids = {}
endif

if !exists(":VenterResize")
	command -nargs=0 VenterResize :call s:ResizeWindows()
endif

if !exists(":VenterClose")
	command -nargs=0 VenterClose :call VenterClose()
endif

function! venter#Venter()
	if exists("t:venter_tabid") && has_key(s:open_winids, t:venter_tabid)
		return
	endif

	if exists("g:venter_disable_vertsplit") && g:venter_disable_vertsplit
		" Remove and hide vertical splitter
		set fillchars+=vert:\ 
		if !exists("s:prevbg")
			let s:prevbg = synIDattr(synIDtrans(hlID("VertSplit")), "bg")
		endif
		if has("gui_running")
			highlight VertSplit guibg=bg
		else
			highlight VertSplit ctermbg=bg
		endif
		let s:vertsplit_hidden = v:true
	endif

	let l:left_winid = s:CreateWindow('topleft')
	let l:right_winid = s:CreateWindow('botright')
	let t:venter_tabid = len(s:open_winids) > 0 ? max(keys(s:open_winids)) + 1 : 1
	execute 'let s:open_winids.'.t:venter_tabid.' = [l:left_winid, l:right_winid]'

	if len(s:open_winids) == 1
		augroup venter
			autocmd VimResized,TabEnter,WinEnter * call s:ResizeWindows()
			if exists('##SafeState')
				autocmd SafeState * call s:DisableStatuslines()
			else
				autocmd WinEnter * call timer_start(0, {-> s:DisableStatuslines()})
			endif
		augroup END
	endif
	call s:ResizeWindows()
	call s:DisableStatuslines()
endfunction

function! venter#VenterToggle()
	if exists("t:venter_tabid") && has_key(s:open_winids, t:venter_tabid)
		call VenterClose()
	else
		call venter#Venter()
	endif
endfunction

function! VenterClose()
	if exists("t:venter_tabid") && has_key(s:open_winids, t:venter_tabid)
		execute 'let l:winids = deepcopy(s:open_winids.'.t:venter_tabid.')'
		for idx in range(0, len(l:winids)-1)
			let l:winnr = win_id2win(l:winids[idx])
			if l:winnr
				execute l:winnr.'wincmd c'
			endif
		endfor
		execute 'unlet s:open_winids.'.t:venter_tabid
		unlet t:venter_tabid
	endif

	call s:CheckWinIds()
endfunction

function! s:CheckWinIds()
	" Check the winids for padding windows in the current tab - remove if no longer valid
	if exists("t:venter_tabid") && has_key(s:open_winids, t:venter_tabid)
		execute 'let l:winids = deepcopy(s:open_winids.'.t:venter_tabid.')'
		for idx in range(0, len(l:winids)-1)
			let l:winnr = win_id2win(l:winids[idx])
			if !l:winnr
				execute 'call remove(s:open_winids.'.t:venter_tabid.', '.idx.')'
			endif
		endfor
	endif

	" If no padding windows in tab, remove tab from dict
	if exists("t:venter_tabid") && has_key(s:open_winids, t:venter_tabid)
		execute 'let l:numwin = len(s:open_winids.'.t:venter_tabid.')'
		if l:numwin == 0
			execute 'unlet s:open_winids.'.t:venter_tabid
		endif
	endif

	" If no padding windows in any tab, remove autocmds and reset VertSplit
	if len(s:open_winids) == 0
		augroup venter
			autocmd!
		augroup END
		augroup! venter

		if exists("g:venter_disable_vertsplit") && g:venter_disable_vertsplit && exists("s:vertsplit_hidden")
			set fillchars-=vert:\ 
			if len(s:prevbg) > 0
				if has("gui_running")
					execute 'highlight VertSplit guibg='.s:prevbg
				else
					execute 'highlight VertSplit ctermbg='.s:prevbg
				endif
			endif
		endif
	endif

	" If there are only padding windows left, close tab and open a new one
	if exists("t:venter_tabid") && has_key(s:open_winids, t:venter_tabid)
		execute 'let l:numwin = len(s:open_winids.'.t:venter_tabid.')'
		execute 'let l:winids = deepcopy(s:open_winids.'.t:venter_tabid.')'
		if winnr('$') == l:numwin
			execute 'unlet s:open_winids.'.t:venter_tabid
			if exists("g:venter_close_tab_if_empty") && g:venter_close_tab_if_empty && tabpagenr('$') > 1
				tabclose
			else
				tabnew
				tabclose -1
			endif
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
	setlocal buftype=nofile bufhidden=wipe nomodifiable nobuflisted

	" Return to previous window if padding window selected
	augroup venter
		autocmd WinEnter <buffer> execute winnr('#').' wincmd w'
	augroup END

	let l:winid=win_getid()
	execute bufwinnr(l:prevbuf).'wincmd w'
	return l:winid
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

function! s:SetToMainWinTextwidth()
	let l:winids = s:GetCurTabWinIds()
	for l:winnr in range(winnr('$'))
		let l:winnr = l:winnr + 1
		let l:winid = win_getid(l:winnr)
		if index(l:winids, l:winid) == -1
			let l:mainwinnr = l:winnr
			break
		endif
	endfor

	if exists("l:mainwinnr")
		let l:bufnr = winbufnr(l:mainwinnr)
		let l:textwidth = getbufvar(l:bufnr, '&textwidth')
	endif

	if exists("l:textwidth") && l:textwidth > 0
		execute l:mainwinnr.'wincmd w'

		" From https://stackoverflow.com/a/26318602
		redir =>a |exe "sil sign place buffer=".l:bufnr|redir end
		let l:signlist=split(a, '\n')
		let l:width=winwidth(l:mainwinnr) - ((&number||&relativenumber) ? &numberwidth : 0) - &foldcolumn - (len(signlist) > 1 ? 2 : 0)

		return float2nr((&columns - &textwidth - (winwidth(l:mainwinnr) + 2 - l:width)) / 2.0)
	endif

	return 0
endfunction

function! s:ResizeWindows()
	call s:CheckWinIds()
	let l:winids = s:GetCurTabWinIds()
	if winnr('$') == 3 && exists("g:venter_use_textwidth") && g:venter_use_textwidth
		let l:venter_width = s:SetToMainWinTextwidth()
		if l:venter_width == 0
			let l:venter_width = exists("g:venter_width") ? g:venter_width : &columns/4
		endif
	else
		let l:venter_width = exists("g:venter_width") ? g:venter_width : &columns/4
	endif
	for l:winid in l:winids
		let l:winnr = win_id2win(l:winid)
		if l:winnr
			execute 'vertical '.l:winnr.'resize '.l:venter_width
			try
				let l:buflines = line('$', l:winid)
			catch /^Vim\%((\a\+)\)\=:E118:/
				let l:buflines = len(getbufline(winbufnr(l:winnr), 1, '$'))
			endtry
			let l:diff = &lines - l:buflines
			if l:diff > 0
				let l:bufnr = winbufnr(l:winnr)
				call setbufvar(l:bufnr, '&modifiable', 1)
				call appendbufline(l:bufnr, l:buflines, map(range(0, l:diff), '""'))
				call setbufvar(l:bufnr, '&modifiable', 0)
			endif
		endif
	endfor
endfunction

function! s:GetCurTabWinIds()
	if exists("t:venter_tabid") && has_key(s:open_winids, t:venter_tabid)
		execute 'let l:winids = deepcopy(s:open_winids.'.t:venter_tabid.')'
		return l:winids
	endif
	return []
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
