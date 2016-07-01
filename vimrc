" plugins
call plug#begin(expand('~/.vim/plugged'))
Plug 'nanotech/jellybeans.vim'
Plug 'itchyny/lightline.vim'
Plug 'easymotion/vim-easymotion'
Plug 'mhinz/vim-startify'
Plug 'vim-scripts/forth.vim'
call plug#end()

" indent
set expandtab
set shiftwidth=2
set tabstop=2
set backspace=2

" search
set ignorecase
set nohlsearch

" do not force write buffer
set hidden

" status
set number
set scrolloff=5
set laststatus=2

" invisibles
set listchars=tab:▸•,eol:¬,trail:•
set nolist

" spell
set spelllang=ru,en

" clipboard
set clipboard+=unnamedplus

" keymap
set langmap=ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯЖ;ABCDEFGHIJKLMNOPQRSTUVWXYZ:,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz

" colors
syntax on
let g:jellybeans_use_term_background_color = 0
let g:jellybeans_use_term_italics = 1
colorscheme jellybeans
set background=dark

" mappings
map <C-L> :set spell!<cr>

" arrows
map <Up> gk
map <Down> gj

" lightline
let g:lightline = {
      \ 'colorscheme': 'jellybeans',
      \ 'component': {
      \   'readonly': '%{&readonly?"x":""}',
      \ },
      \ 'separator': { 'left': '', 'right': '' },
      \ 'subseparator': { 'left': '|', 'right': '|' }
      \ }

" easymotion
let g:EasyMotion_do_mapping = 0 " Disable default mappings
let g:EasyMotion_smartcase = 1 " Turn on case insensitive feature
nmap s <Plug>(easymotion-overwin-f2)
nmap t <Plug>(easymotion-t2)
map <Leader>w <Plug>(easymotion-w)
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)
map  / <Plug>(easymotion-sn)
omap / <Plug>(easymotion-tn)
map  n <Plug>(easymotion-next)
map  N <Plug>(easymotion-prev)
