function vlcstream
	set -x DISPLAY :0
vlc -f udp://@:1234
end
