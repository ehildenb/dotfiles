#!/usr/bin/zsh

# Script to play videos from recognized sites using mpv instead
# Adopted (very loosely) from: http://www.uzbl.org/wiki/ytvp

# Recognizes any website that youtube-dl supports (requires youtube-dl)

# Could possibly put in a command to check youtube-dl for an error - then display it somehow with a dialog
# Or perhaps have a little status bar that pops up and displays the results for a few seconds?

# Default to just playing with mpv (not queueing)
# If the first parameter is "queue", then run with umpv
# If the first parameter is "queue" or "play", then shift it out
MEDIA_ACTION="$1"
shift

# If there is a second parameter, it's the uri to use, if not, use UZBL's current URI
if [[ -n "$1" ]]
then
    MEDIA_URI="$1"
else
    MEDIA_URI="$UZBL_URI"
fi

echo "@@@MEDIA_ACTION $MEDIA_ACTION"
echo "@@@MEDIA_URI ${MEDIA_URI[@]}"

# If we are downloading the video
if [[ "$MEDIA_ACTION" == 'download' ]]
then
    # Source the aliases file, because for some reason the aliases aren't defined
    source ~/.aliases
    music-dl ${MEDIA_URI[@]}
    exit
fi

# Pull video URI
MEDIA_URI=($(youtube-dl -f "best" -g "$MEDIA_URI"))

# Only attempt to open it and clear the command if it's a 'valid' uri
if [[ -n "$MEDIA_URI" ]]
then
    if [[ "$MEDIA_ACTION" == 'play' ]]
    then
        mpv -vo=opengl ${MEDIA_URI[@]}
    elif [[ "$MEDIA_ACTION" == 'queue' ]]
    then
        umpv ${MEDIA_URI[@]}
    fi
fi
