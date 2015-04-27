" neobundle
if has('vim_starting')
    set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

call neobundle#begin(expand('~/.vim/bundle'))

NeoBundleFetch 'Shougo/neobundle.vim'

NeoBundle 'Shougo/neocomplete.vim'

NeoBundle 'Shougo/neosnippet.vim'

NeoBundle 'Shougo/neosnippet-snippets'

NeoBundle 'bling/vim-airline'

NeoBundle 'chriskempson/vim-tomorrow-theme'

NeoBundle 'scrooloose/nerdtree'

NeoBundle 'scrooloose/nerdcommenter'

NeoBundle 'mattn/emmet-vim'

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
set scrolloff=5
set laststatus=2
set statusline=\%F%m%r%h\ %w\ [%l,%v][%p%%]

" invisibles
set listchars=tab:▸•,eol:¬,trail:•
set list

" spell
set spelllang=ru,en

" Keymap
set keymap=russian-jcukenwin
set iminsert=0
set imsearch=0

" colors
syntax on
set t_Co=256
set background=dark
colorscheme Tomorrow-Night
if has('gui_running')
    set guifont=Meslo\ LG\ S\ for\ Powerline:h15
    set guioptions-=r
    set guioptions-=L
    set guioptions-=m
endif

" Mappings
map <C-h> :noh<cr>
map <C-L> :set spell!<cr>

" Русская раскладка
imap <C-L> <C-^>

" NeoComplete
let g:neocomplete#enable_at_startup = 1

" NeoSnippet
imap <C-k>     <Plug>(neosnippet_expand_or_jump)
smap <C-k>     <Plug>(neosnippet_expand_or_jump)
xmap <C-k>     <Plug>(neosnippet_expand_target)

" Airline
let g:airline_powerline_fonts=1
let g:airline_theme='tomorrow'

" NERD Tree
let g:NERDTreeChDirMode=2
map <C-n> :NERDTreeToggle<cr>

" NERD commenter
map <C-c> <leader>c<space>

" Emmet
autocmd FileType html imap <C-e> <C-y>,
autocmd FileType html map <C-e> <C-y>,
