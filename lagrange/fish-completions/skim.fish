function __fish_complete_pdf --description 'Complete using PDF files' --argument comp
	set desc (_ PDF file)
	if test (count $argv) -gt 1
		set desc $argv[2]
	end
	eval "set pdfs "$comp"*.pdf" ^/dev/null
	if test $pdfs[1]
		printf "%s\t$desc\n" $pdfs
	end
end

complete -c skim -x -a "(__fish_complete_pdf (commandline -ct))"
