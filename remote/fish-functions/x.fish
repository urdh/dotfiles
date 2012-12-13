function x
	set THETTY (tty | sed -e 's/^.*\(.\)$/\1/')
	exec startx -- :$THETTY
end
