# Fish git prompt
set __fish_git_prompt_showdirtystate 'yes'
set __fish_git_prompt_showstashstate 'yes'
set __fish_git_prompt_showuntrackedfiles 'yes'
set __fish_git_prompt_showupstream 'yes'
set __fish_git_prompt_color_branch brown
set __fish_git_prompt_color_upstream_ahead green
set __fish_git_prompt_color_upstream_behind red

# Status Chars
set __fish_git_prompt_char_dirtystate '⚡'
set __fish_git_prompt_char_stagedstate '→'
set __fish_git_prompt_char_untrackedfiles '☡'
set __fish_git_prompt_char_stashstate '↩'
set __fish_git_prompt_char_upstream_ahead '+'
set __fish_git_prompt_char_upstream_behind '-'

set -e fish_greeting

function fish_prompt
  set_color red; echo -n $USER
  set_color normal; printf ' at '
  set_color brown; echo -n (hostname)
  set_color normal; echo -n ' in '
  set_color green; echo -n (prompt_pwd)
  set_color normal; echo -n (__fish_git_prompt)
  set_color normal; echo -n ' # '
end

function fish_right_prompt
  set_color normal; printf '[%s]' (date +%H:%M:%S)
end
