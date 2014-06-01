function cless --description 'Less, with syntax highlighting'
	pygmentize -g $argv | less -R
end
