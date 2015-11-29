#!/bin/bash

# Blocks scripts/plugins for websites not on a whitelist
# Taken (very very loosely) from http://www.uzbl.org/wiki/noscript

# Note! This is NOT meant as an ad-blocker. It will either allow ALL scripts on a page, or NONE
# I am using this because I don't want scripts/plugins running unless I say it's ok - then they are all welcome
# To combat ads (malicious or not), I'll use privoxy or polipo

# For some reason, I can't get uzbl to pass the correct states of variables enable_scripts and enable_plugins
# Once I do that, I can have saner behavior for how to allow/block scripts
# Or perhaps I should just write a temporary file where scripts are allowed?
# But I would prefer to keep it per-browser window also, not just per-site

SCRIPTS_ENABLED=0
PLUGINS_ENABLED=0

# If scripts/plugins are already enabled, allow it to keep being enabled - toggling is done with a keybinding
# Scratch that - have to whitelist away - can't seem to get it to pass whether they're enabled or not correctly
if [[ ! -n "$1" ]]
then
    echo 'set enable_scripts = 0' > "$UZBL_FIFO"
else
    SCRIPTS_ENABLED="$1"
fi
if [[ ! -n "$2" ]]
then
    echo 'set enable_plugins = 0' > "$UZBL_FIFO"
else
    PLUGINS_ENABLED="$1"
fi

# If they're both enabled - no point loading and searching a whitelist
if [[ "$PLUGINS_ENABLED" == "1" && "$SCRIPTS_ENABLED" == "1" ]]
then
    exit
fi

# Whitelist file, could have separate ones for scripts/plugins?
WHITELIST="$XDG_DATA_HOME/uzbl/js-plugins-whitelist"

# Read in the file, compare to the $UZBL_URI, if we find a regex match, enable scripts and plugins
while read -r line; do
    # Allow comments in the file (easier to use some of the easylists)
    if [[ "${line:0:1}" != "#" ]]
    then
        if [[ "$UZBL_URI" =~ "$line" ]]
        then
            # If we find it in our whitelist, enable it
            echo 'set enable_scripts = 1' > "$UZBL_FIFO"
            echo 'set enable_plugins = 1' > "$UZBL_FIFO"
            exit
        fi
    fi
done < "$WHITELIST"
