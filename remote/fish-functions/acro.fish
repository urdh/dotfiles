function acro --description 'Open PDF in acrobat reader'
	set fname (echo $argv | gawk -F'.' '{print $1}')
        acroread "$fname.pdf" &
end
