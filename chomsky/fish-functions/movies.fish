function movies
  switch $argv[1]
    case on
      afp_client mount -u ssimon -p - lagrange.local:Movies /media/movies
    case off
      afp_client unmount /media/movies 
    case play
      omxplayer -p -o hdmi "$argv[2]"
  end
end
