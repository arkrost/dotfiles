" Leave INSERT mode
inoremap jj <ESC>
" NERDTree toggle
nnoremap <C-n> :NERDTreeToggle<cr>
" Smart way to move between windows
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l
" Close the current buffer
map <leader>bd :Bclose<cr>
" Close all the buffers
map <leader>ba :1,1000 bd!<cr>
" Useful mappings for managing tabs
map <leader>tn :tabnew<cr>
map <leader>tt :tabnext<cr>
" Save & quit
map <leader>w :w!<cr>
map <leader>q :q<cr>
