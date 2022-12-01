#!/usr/bin/env sh
pandoc --metadata title="Pinenote Greetings" -f gfm --toc -s pn_handbook.md > greet.html
