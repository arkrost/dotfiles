"============== Filetype stuff ===============
filetype plugin on
filetype indent on

" Load custom settings
source ~/.vim/startup/settings.vim
source ~/.vim/startup/mappings.vim

"=================== VAM =====================
set runtimepath+=~/.vim/addons/vim-addon-manager
call vam#ActivateAddons(['github:scrooloose/nerdtree'])
call vam#ActivateAddons(['github:bak/vim-scala'])
call vam#ActivateAddons(['github:Townk/vim-autoclose'])
