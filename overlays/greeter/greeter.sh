#!/usr/bin/env sh

test -e $HOME/.config/pinenote/disable_greeter && exit


epiphany-browser /etc/greeter/greet.html&

test -d $HOME/.config/pinenote || mkdir $HOME/.config/pinenote
touch $HOME/.config/pinenote/disable_greeter
