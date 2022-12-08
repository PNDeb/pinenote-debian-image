#!/usr/bin/env sh

test -e $HOME/.config/pinenote/disable_greeter && exit


firefox-esr /etc/greeter/greet.html&

test -d $HOME/.config/pinenote || mkdir $HOME/.config/pinenote

touch $HOME/.config/pinenote/disable_greeter

disable_overview_file="$HOME/.config/pinenote/do_not_show_overview"
test -e ${disable_overview_file} && rm "${disable_overview_file}"
