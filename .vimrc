" neobundle
if has('vim_starting')
    set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

call neobundle#begin(expand('~/.vim/bundle'))

NeoBundleFetch 'Shougo/neobundle.vim'
NeoBundle 'altercation/vim-colors-solarized'
NeoBundle 'scrooloose/nerdtree'
NeoBundle 'scrooloose/nerdcommenter'
NeoBundle 'mattn/emmet-vim'
NeoBundle 'Valloric/YouCompleteMe', {
    \    'build' : { 'others' : './install.sh' }
    \ }

call neobundle#end()
 "vundle
"Plugin 'Valloric/YouCompleteMe'
filetype plugin indent on
NeoBundleCheck
" encoding
set encoding=utf-8
set autoread
" indent
set expandtab
set autoindent
set shiftwidth=4
set tabstop=4
" search 
set ignorecase
set hlsearch
set incsearch
" backup
set nobackup
set noswapfile
set nowb
set hidden
" status
set number
set laststatus=2
set statusline=\%F%m%r%h\ %w\ [%l,%v][%p%%]
" colors
syntax on
set background=dark
set t_Co=256
let g:solarized_termcolors=256
colorscheme solarized
if has('gui_running') 
    set guifont=Menlo\ Regular:h14
    set guioptions-=r
    set guioptions-=L
    set guioptions-=m
endif
" NERD Tree
let g:NERDTreeChDirMode=2
" Mappings
map <C-h> :noh<cr>
 " nerd tree
map <C-n> :NERDTreeToggle<cr> 
 " nerd commenter
map <C-c> <leader>c<space>
 " emmet
autocmd FileType html imap <C-e> <C-y>,
 " emmet
autocmd FileType html map <C-e> <C-y>,
