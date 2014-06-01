function x --description 'Start X on next available TTY'
	set THETTY (tty | sed -e 's/^.*\(.\)$/\1/')
	exec startx -- :$THETTY
end
