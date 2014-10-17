function cdiff --description 'Diff, with syntax highlighting'
	diff $argv | pygmentize -l diff
end
