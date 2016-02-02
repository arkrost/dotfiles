" plugins
call plug#begin(expand('~/.config/nvim/plugged'))
Plug 'bling/vim-airline'
Plug 'morhetz/gruvbox'
Plug 'Shougo/deoplete.nvim'
Plug 'Shougo/unite.vim'
Plug 'easymotion/vim-easymotion'
call plug#end()
filetype plugin indent on

" indent
set expandtab
set shiftwidth=2
set tabstop=2

" search
set ignorecase

" do not force write buffer
set hidden

" status
set number
set scrolloff=5

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
colorscheme gruvbox
set background=dark

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

" easymotion
let g:EasyMotion_do_mapping = 0 " Disable default mappings
let g:EasyMotion_smartcase = 1 " Turn on case insensitive feature
nmap s <Plug>(easymotion-overwin-f2)
nmap t <Plug>(easymotion-t2)
map <Leader>w <Plug>(easymotion-w)
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)
