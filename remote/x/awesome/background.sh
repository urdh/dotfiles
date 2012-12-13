#!/bin/bash
if [ -z "$(xrandr -q | grep 1680)" ]; then awsetbg -a /chalmers/users/ssimon/.background; fi
if [ -n "$(xrandr -q | grep 1680)" ]; then awsetbg -a /chalmers/users/ssimon/.background-wide; fi

