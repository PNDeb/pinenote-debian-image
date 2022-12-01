#!/usr/bin/env sh
dev_stylus=$(libinput list-devices | tail -n +`libinput list-devices | grep -e "w9013 2D1F:0095 Stylus" -n | cut -f 1 -d ":"` | head -2 | tail -1 | cut -f 2 -d ":" | xargs)
dev_buttons=$(libinput list-devices | tail -n +`libinput list-devices | grep -e "ws8100_pen" -n | cut -f 1 -d ":"` | head -2 | tail -1 | cut -f 2 -d ":" | xargs)

echo "Found stylus at ${dev_stylus}"
echo "Found pen buttons at ${dev_buttons}"

echo "Setting up sieve:"

/root/bin/evsieve \
	--input ${dev_stylus} grab \
	--input ${dev_buttons} grab \
	--output

