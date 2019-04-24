#!/usr/local/bin/fish
if status --is-login
    source ~/.config/fish/profile.fish
    source ~/.iterm2_shell_integration.fish ^/dev/null
end
