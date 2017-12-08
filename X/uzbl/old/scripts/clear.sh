#!/bin/zsh

# Remove the history, cookies, and session cookies
cd $XDG_DATA_HOME/uzbl
rm history session-cookies.txt cookies.txt
printf '@set_status Cleared!\n@set_mode\nevent KEYCMD_CLEAR\n' > "$UZBL_FIFO"
