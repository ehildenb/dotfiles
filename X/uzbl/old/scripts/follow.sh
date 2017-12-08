#!/bin/bash

# This scripts acts on the return values of the script file follow.js

# To call this script
# follow.sh ACTION [KEYS_PRESSED]

# ACTION possibilities:
# [clear][array][click|new|set|media[play|queue]|input|copy]
# clear:  clear the uzbl_follow_data js object to default values, clear command, set default mode, exit
# array:  continue requesting link follows after links are selected
# click:  js script will simulate a mouse click on the element
# new:    open a new window with the requested uri/element in it
# set:    set the current pages uri to the requested element uri/src
# media:  call the media handler with the requested uri/src (play/queue are @media_handler specific)
    # mediaplay:   open new instance of media player with uri/src
    # mediaqueue:  append media to queueing media player
# input:  only look for input type fields in js - simulate mouse click on them
# copy:   copy uri/src of requested follow link to clipboard

# Examples:
# follow.sh arraymediaqueue
#   No follow keys have been pressed yet, when a link is selected tell the @media_handler to queue
#       the selected file to our queueing media player, immediately request another follow upon success
# follow.sh new e
#   Open the selected link in a new window, return to normal mode upon finish
#       Hints that begin with the letter e are the only ones that remain showing at this point
# follow.sh arrayclick
#   Open selected link in current window by simulating mouse click
#       immediately request a new follow on the new page (page may not be done loading yet)


# The first argument will be what to do with the link/element - necessary argument
[[ -z "$1" ]] && exit
ACTION=$1
shift

# If we're requesting that the hints be cleared, doesn't allow parsing of any other part of the command
if [[ "$ACTION" == clear* ]]
then
    printf 'js uzbl_follow_data.clear()\n' > "$UZBL_FIFO"
    printf '@set_status done\n@set_mode\nevent KEYCMD_CLEAR\n' > "$UZBL_FIFO"
    exit
fi

# If a array-follow has been requested
ARRAY_FOLLOW="0"
if [[ "$ACTION" == array* ]]
then
    ARRAY_FOLLOW="1"
    ACTION="${ACTION#array}"
fi

# The second argument will be the follow keys pressed
# If there are no follow keys pressed yet, we "requestFollow"
KEYS_PRESSED=""
if [[ -z "$1" || "$1" == "" ]]
then
    # Get output from requesting a follow, check for errors
    REQUEST_FOLLOW="$( printf 'js uzbl_follow_data.request_follow("@follow_hint_keys", "'"$ACTION"'")\n' | socat - "unix-connect:$UZBL_SOCKET" | tail -n4 | awk '/^-.+:/ {print}')"
#    if [[ "$REQUEST_FOLLOW" != -success:* ]]
#    then
#        printf '@set_mode\nevent KEYCMD_CLEAR\n' > "$UZBL_FIFO"
#        printf '@set_status Error following\n' > "$UZBL_FIFO"
#        echo "Error following: $REQUEST_FOLLOW"
#    echo "markeraou"
#        exit
#    fi
else
    KEYS_PRESSED="$1"
    echo "KEYS_PRESSED: $KEYS_PRESSED"
    shift
fi

# Update our char field - with whatever is in KEYS_PRESSED, get the output
RESULT_FOLLOW="$( printf 'js uzbl_follow_data.update_chars("'"$KEYS_PRESSED"'")\n' | socat - "unix-connect:$UZBL_SOCKET" | tail -n4 | awk '/^-.+:/ {print}')"

# Split RESULT_FOLLOW into the type of message and the message
INDEX_SPLIT="$(expr index "$RESULT_FOLLOW" ":")"
ARG_TYPE=""
ARG_MSG=""
if [[ "$INDEX_SPLIT" == "0" ]]
then
    ARG_TYPE="$RESULT_FOLLOW"
    ARG_MSG="$ARG_TYPE"
else
    ARG_TYPE="${RESULT_FOLLOW:1:(($INDEX_SPLIT - 2))}"
    ARG_MSG="${RESULT_FOLLOW:$INDEX_SPLIT}"
fi

echo "ACTION:   $ACTION"
echo "ARG_TYPE: $ARG_TYPE"
echo "ARG_MSG:  $ARG_MSG"

case "$ARG_TYPE" in
    # Test for errors from js file
    *error*)
        printf '@set_status Error following\n' > "$UZBL_FIFO"
        echo "Error following: $ARG_MSG"
        exit
        ;;

    # Test if a bad character was entered
    badchar*)
        printf '@set_status No matches\n' > "$UZBL_FIFO"
        exit
        ;;

    # If there are still multiple matches
    multmatch*)
        printf '@set_status '"$ARG_MSG"' matches\n' > "$UZBL_FIFO"
        exit
        ;;

    # go into our action statements
    uri*)
        case "$ACTION" in
            # Set uri
            set*)
                ACTION=${ACTION#set}
                printf "uri $ARG_MSG"'\n' | sed -e 's/@/\\@/' > "$UZBL_FIFO"
                printf '@set_status Uri set\n' > "$UZBL_FIFO"
                ;;

            # New window
            new*)
                printf 'event NEW_WINDOW '"$ARG_MSG"' \n' > "$UZBL_FIFO"
                printf '@set_status New window opened\n' > "$UZBL_FIFO"
                ;;

            # Copy to clipboard
            copy*)
                printf "$ARG_MSG"'\n' | xclip
                printf '@set_status Copied to clipboard\n' > "$UZBL_FIFO"
                ;;

            # Follow a media link with the set media handler (default to play, not queue)
            media*)
                METHOD="play"
                [[ "$ACTION" == *queue* ]] && METHOD="queue"
                [[ "$ACTION" == *download* ]] && METHOD="download"
                printf '@media_handler '"$METHOD $ARG_MSG"'\n' > "$UZBL_FIFO"
                printf '@set_status Attempted media '"$METHOD"'\n' > "$UZBL_FIFO"
                ;;

            # Handles all other cases when a uri is returned
            *)
                printf '@set_status Undef follow mode '"$ACTION"'\n' > "$USBL_FIFO"
                ;;
        esac
        ;;

    # Statement was clicked, or input was selected
    click*|input*)
        printf '@set_status Clicked!\n' > "$UZBL_FIFO"
        ;;
    *)
        printf '@set_status Error: Follow - '"$ACTION"' requires uri\n' > "$UZBL_FIFO"
        ;;
esac

# If in array follow mode, clear out the input and inject the same keybinding we had before
if [[ "$ARRAY_FOLLOW" == "1" ]]
then
    printf 'event SET_KEYCMD\n' > "$UZBL_FIFO"
    # To hackishly refocus the window - race condition anyone?
    [[ "$ACTION" == *new* ]] && printf "sh 'sleep 1 && i3-msg [id=\"$UZBL_XID\"] focus'\n" > "$UZBL_FIFO"

# Otherwise set back to default mode, clear input
else
    printf '@set_mode\nevent KEYCMD_CLEAR\n' > "$UZBL_FIFO"
fi
