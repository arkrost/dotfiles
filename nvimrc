" plugins
set runtimepath^=~/.cache/dein/repos/github.com/dein.vim
call dein#begin(expand('~/.cache/dein'))
call dein#add('Shougo/dein.vim')
call dein#add('itchyny/lightline.vim')
call dein#add('morhetz/gruvbox')
call dein#add('Shougo/deoplete.nvim')
call dein#add('Shougo/unite.vim')
call dein#add('easymotion/vim-easymotion')
call dein#add('wting/rust.vim')
call dein#add('racer-rust/vim-racer')
call dein#end()

filetype plugin indent on

" indent
set expandtab
set shiftwidth=2
set tabstop=2

" search
set ignorecase
set nohlsearch

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
"nmap h :noh<cr>
map <C-L> :set spell!<cr>

" arrows
map <Up> gk
map <Down> gj

" русская раскладка
imap <C-L> <C-^>

" lightline
let g:lightline = {
      \ 'colorscheme': 'gruvbox',
      \ 'component': {
      \   'readonly': '%{&readonly?"x":""}',
      \ },
      \ 'separator': { 'left': '', 'right': '' },
      \ 'subseparator': { 'left': '|', 'right': '|' }
      \ }

" deoplete
let g:deoplete#enable_at_startup = 1

" racer
let g:racer_cmd = expand('~/.rust/racer/target/release/racer')

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
