function git_prompt
	if git rev-parse 2> /dev/null
		set branch (git status -b --porcelain | egrep -ox '## (.*)' | cut -d" " -f2 | awk -F'[.]{3}' '{print $1}')
		set head (git log -1 --abbrev-commit --pretty=format:%h)
		set gitstatus (git status -b --porcelain)
		set outgoing (git log -1 --pretty=format:%h --abbrev-commit $branch --not --remotes)
		set incoming (git log -1 --abbrev-commit --pretty=format:%h --remotes --not $branch)
		# print the branch name
		echo -n " "(set_color --bold black)
		echo -n $branch
		# print the commit number
		echo -n (set_color --bold yellow)
		echo -n $head
		# print the indicator
		echo -n (set_color --bold red)
		# red question mark: unversioned files present
		if test (echo $gitstatus | egrep -ox '\?\? (.*)' | head -n1)
			echo -n (set_color --bold red)"?"
		# red exclamation point: uncommited, unadded changes
		else if test (echo $gitstatus | egrep -ox ' [UMADRC] (.*)' | head -n1)
			echo -n (set_color --bold red)"!"
		# green exclamation point: uncommitted, added changes
		else if test (echo $gitstatus | egrep -ox '[UMADRC]  (.*)' | head -n1)
			echo -n (set_color --bold green)"!"
		# red minus: outgoing AND incoming commits
		else if test (echo $outgoing)
			if test (echo $incoming)
				echo -n (set_color --bold red)"-"
			else
		# gray plus: outgoing commits
				echo -n (set_color --bold black)"+"
			end
		# gray minus: incoming commits
		else if test (echo $incoming)
			echo -n (set_color --bold black)"-"
		end
	end
end

function hg_prompt
	hg prompt " "(set_color --bold black)"{branch}"(set_color --bold yellow)"{rev}"(set_color --bold red)"{status}" 2> /dev/null
end

function fish_prompt --description 'Write out the prompt'
	printf '%s@%s%s %s%s%s%s> ' (whoami) (hostname|cut -d . -f 1) (set_color $fish_color_cwd) (prompt_pwd) (hg_prompt) (git_prompt) (set_color normal)
end
