set tabstop=2 softtabstop=2
set smartindent
set nu
set hidden
set belloff=all
set virtualedit=all

set noswapfile
set nobackup

set incsearch
augroup vimrc-incsearch-highlight
	autocmd!
	autocmd CmdlineEnter /,\? :set hlsearch
	autocmd CmdlineLeave /,\? :set nohlsearch
augroup END

syntax on
colorscheme default
