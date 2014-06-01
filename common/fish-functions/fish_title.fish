function fish_title --description 'Set terminal title'
	if set -q fish_title_disabled
		return
	end

	set -l pwd (prompt_pwd)
	set -l job "$_"
	if test $_ = ssh
		set -g fish_title_string 'ssh'
	else if test $_ != fish
		set -g fish_title_string (printf '%s (%s)' $job $pwd)
	else
		set -g fish_title_string (printf '%s' $pwd)
	end
	echo $fish_title_string
end
