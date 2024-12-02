#!/bin/sh

killall lisgd || true 
lisgd -d /dev/input/by-path/platform-fe5e0000.i2c-event \
    -g "4,DU,*,*,R,xournalpp &" \
    -g "3,DU,*,*,R,toggle_onscreen_keyboard.py &" \
    -g "3,UD,*,*,R,refresh_screen &" \
    -g "3,LR,*,*,R,sway_workspace goto prev &" \
    -g "3,RL,*,*,R,sway_workspace goto next &" \
    -g "4,LR,*,*,R,sway_workspace move prev &" \
    -g "4,RL,*,*,R,sway_workspace move next &" \
    -g "4,UD,*,*,R,toggle_menu.sh &" &
