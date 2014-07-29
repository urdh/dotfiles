function __fish_complete_markdown --description 'Complete using markdown files' --argument comp
	set desc (_ PDF file)
	if test (count $argv) -gt 1
		set desc $argv[2]
	end
	eval "set mdowns "$comp"*.{md,mdown,markdown}"
	if test $mdowns[1]
		printf "%s\t$desc\n" $mdowns
	end
end

complete -c md -x -a "(__fish_complete_markdown (commandline -ct))"
