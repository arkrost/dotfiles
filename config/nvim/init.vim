call plug#begin(expand('~/.config/nvim/plugged'))

Plug 'bling/vim-airline'

Plug 'morhetz/gruvbox'

Plug 'scrooloose/nerdtree'

Plug 'scrooloose/nerdcommenter'

Plug 'tpope/vim-fugitive'

Plug 'Shougo/deoplete.nvim'

call plug#end()
filetype plugin indent on

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
set nowritebackup
set hidden

" status
set number
set scrolloff=5
set laststatus=2

" invisibles
set listchars=tab:▸•,eol:¬,trail:•
set list

" spell
set spelllang=ru,en

" clipboard
set clipboard+=unnamedplus

" keymap
set keymap=russian-jcukenwin
set iminsert=0
set imsearch=0

" colors
let $NVIM_TUI_ENABLE_TRUE_COLOR=1
syntax on
set t_Co=256
set background=dark
colorscheme gruvbox

" mappings
map <C-h> :noh<cr>
map <C-L> :set spell!<cr>

" arrows
map <Up> gk
map <Down> gj

" русская раскладка
imap <C-L> <C-^>

" airline
let g:airline_powerline_fonts=1
let g:airline_theme='gruvbox'

" NERD Tree
let g:NERDTreeChDirMode=2
map <C-n> :NERDTreeToggle<cr>

" NERD commenter
map <C-c> <leader>c<space>
