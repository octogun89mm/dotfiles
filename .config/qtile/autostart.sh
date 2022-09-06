#!/bin/bash

picom -b --experimental-backends &
sleep 0.2 &
wal -R -n &
~/.fehbg &
pa-applet &
emacs --daemon &
