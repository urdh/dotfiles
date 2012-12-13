function acro
	set fname (echo $argv | gawk -F'.' '{print $1}')
        acroread "$fname.pdf" &
end
