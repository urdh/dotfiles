function ccat --description 'Cat, with syntax highlighting'
	pygmentize -g $argv | cat
end
