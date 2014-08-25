function fish_greeting --description 'Print the shell greeting'
	set c_n (printf "%s%s" (set_color normal) (set_color normal))
	set c_w (printf "%s%s" (set_color normal) (set_color cyan))

	set location (printf "%sWelcome to %s%s%s" $c_n $c_w (hostname) $c_n)
	set system (printf "%sRunning %s%s%s on %s%s%s" $c_n $c_w (uname -mrs) $c_n $c_w (tty | sed -e 's/.*tty\(.*\)/\1/') $c_n)
	set datetime (printf "%sIt is %s%s%s (%s) on %s%s%s" $c_n $c_w (date +%T) $c_n (date +%Z) $c_w (date +%F) $c_n)
	# date '+%Aen den %e %B %Y'

	printf "\n  %s\n  %s\n  %s\n" $location $system $datetime
	# Disabled for now
	#if set -q SSH_CLIENT
	#	set lasttest (last -d 2>&1 | head -n1)
	#	if test $lasttest = 'last: illegal option -- d'
	#		set lasthost (last -2 $USER | head -n2 | tail -n1 | awk '{print $3}')
	#		set lasttime 'c'
	#	else
	#		set lasthost (last -2 -da $USER 2>/dev/null | head -n2 | tail -n1 | awk '{print $NF}')
	#		set lasttime 'b'
	#	end
	#	set lastlogin (printf "%sLast login from %s%s%s, %s%s%s ago" $c_n $c_w $lasthost $c_n $c_w $lasttime $c_n)
	#	printf "  %s\n" $lastlogin
	#end
	printf "\n"
end
