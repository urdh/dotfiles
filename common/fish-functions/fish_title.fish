function fish_title
	if set -q fish_title_disabled
		return
	end

	set -l hostname (whoami)@(hostname|cut -d . -f 1)
	set -l pwd (prompt_pwd)
	set -l job "$_"
	if test $_ != fish
		set -g fish_title_string (printf '%s (%s) [%s]' $job $pwd $hostname)
	else
		set -g fish_title_string (printf '%s [%s]' $pwd $hostname)
	end
	echo $fish_title_string
end
