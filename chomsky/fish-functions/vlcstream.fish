function vlcstream --description 'Set up a VLC reciever'
	set -x DISPLAY :0
vlc -f udp://@:1234
end
