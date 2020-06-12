# vim-venter

vim-venter is a vim plugin that vertically centers the current window(s)

![](demo.gif)

This is mainly useful when working with one file on a large monitor

Similar to [goyo.vim](https://github.com/junegunn/goyo.vim) but keeps the functionality (statusbar, tabline etc.)

## Installation

#### vim-plug

Add `Plug 'jmckiern/vim-venter'` to .vimrc  
Then run `:PlugInstall` in vim

#### Vundle.vim

Add `Plugin 'jmckiern/vim-venter'` to .vimrc  
Then run `:PluginInstall` in vim

#### Pathogen

Run `git clone https://github.com/jmckiern/vim-venter ~/.vim/bundle/vim-venter` in a terminal

## How to Use

### Commands

`:Venter` - Open venter

`:VenterClose` - Close venter

`:VenterResize` - Force a window resize (usually only happens on VimResized, TabEnter and WinEnter events)

### Options

`g:venter_disable_vertsplit` - Set to `v:true` before calling `:Venter` to disable the vertical window separators

`g:venter_width` - Manually set width of padding windows (defaults to `&columns/4`)
