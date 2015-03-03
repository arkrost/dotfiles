" neobundle
if has('vim_starting')
    set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

call neobundle#begin(expand('~/.vim/bundle'))

NeoBundleFetch 'Shougo/neobundle.vim'

NeoBundle 'bling/vim-airline'

NeoBundle 'altercation/vim-colors-solarized'

NeoBundle 'scrooloose/nerdtree'

NeoBundle 'scrooloose/nerdcommenter'

NeoBundle 'mattn/emmet-vim'

NeoBundle 'Valloric/YouCompleteMe', {
    \    'build' : {
    \               'unix' : './install.sh',
    \               'mac'  : './install.sh'
    \              }
    \ }

NeoBundle 'tpope/vim-fugitive'

NeoBundle 'rust-lang/rust.vim'

call neobundle#end()
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
set t_Co=256
set background=dark
let g:solarized_termcolors=256
colorscheme solarized
if has('gui_running') 
    set guifont=Meslo\ LG\ S\ for\ Powerline:h15 
    set guioptions-=r
    set guioptions-=L
    set guioptions-=m
endif

" Mappings
map <C-h> :noh<cr>

" Airline
let g:airline#themes#base16#constant = 1
let g:airline_theme = 'base16'
let g:airline_powerline_fonts = 1

" NERD Tree
let g:NERDTreeChDirMode=2
map <C-n> :NERDTreeToggle<cr> 

" NERD commenter
map <C-c> <leader>c<space>

" Emmet
autocmd FileType html imap <C-e> <C-y>,
autocmd FileType html map <C-e> <C-y>,
