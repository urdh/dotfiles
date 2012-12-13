#!~local/bin/fish
if status --is-login
    . ~/.config/fish/profile
end

clear                                                                       
echo "Inloggad som \"$USER\" på $HOSTNAME."                                 
echo "Klockan är" (date +%R)", och idag är det" (date "+%Aen den %d %B")  
if test -s ~/.notes
  echo 
  echo -n "Anteckningar: "                                                   
  cat ~/.notes                                                                
end
echo

if test $__fish_prompt_hostname = "vcs32-5"; set -x -g __fish_prompt_hostname (echo -ne "\033[33munsup\033[m"); end
if test $__fish_prompt_hostname = "vcs64-5"; set -x -g __fish_prompt_hostname (echo -ne "\033[1;33munsup64\033[m"); end
