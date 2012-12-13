function git_prompt
	if git rev-parse 2> /dev/null
		echo -n " "(set_color --bold black)
		echo -n (git status -b --porcelain | egrep -ox '## (.*)' | cut -d" " -f2 | awk -F'[.]{3}' '{print $1}')
		echo -n (set_color --bold yellow)
		echo -n (git log -1 --abbrev-commit --pretty=format:%h)
		echo -n (set_color --bold red)
		if test (git status -b --porcelain | egrep -ox 'A  (.*)')
			echo -n "!"
		else
			if test (git status -b --porcelain | egrep -ox '\?\? (.*)')
				echo -n "?"
			end
		end
	end
end

function hg_prompt
	hg prompt " "(set_color --bold black)"{branch}"(set_color --bold yellow)"{rev}"(set_color --bold red)"{status}" 2> /dev/null
end

function fish_prompt --description 'Write out the prompt'
	printf '%s@%s%s %s%s%s%s> ' (whoami) (hostname|cut -d . -f 1) (set_color $fish_color_cwd) (prompt_pwd) (hg_prompt) (git_prompt) (set_color normal)
end
