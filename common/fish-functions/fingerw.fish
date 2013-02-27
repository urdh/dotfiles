function fingerw
	w -hs | awk -F' ' '{print $1}' | grep -v $USER | uniq | xargs finger
end
