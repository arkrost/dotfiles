set fish_color_normal ebebff white
set fish_color_error e06c75 red
set fish_color_command e5c07b yellow
set fish_color_param normal
set fish_color_autosuggestion abb2bf blue 
set fish_color_operator c8ae9d bryellow
set fish_color_valid_path normal
set fish_color_search_match --background=282c34 --background=brblack

set fish_pager_color_description $fish_color_operator
set fish_pager_color_prefix normal
set fish_pager_color_completion $fish_color_autosuggestion
set fish_pager_color_progress $fish_pager_color_description

function fish_prompt
  set_color 8787af cyan; echo -n (prompt_pwd)
  set_color normal; echo -n ' '
  set_color d75f5f red; echo -n '❯'
  set_color ffaf5f yellow; echo -n '❯'
  set_color 87af5f green; echo -n '❯'
  set_color normal; echo -n ' '
end

set PATH $PATH /usr/local/bin $HOME/.cargo/bin
