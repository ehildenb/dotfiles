#!/bin/zsh

# This scripts acts on the return values of the script file follow.js

# To call this script
# follow.sh JS_ACTION SH_ACTION [KEYS_PRESSED]

# JS_ACTION
# [uri|click|class]
# uri: return the uri of the selected link
# click: click the selected link
# class: select all hints with the same class

# SH_ACTION
# [current|new|input|play|queue|download]
# current: Stay in current page with action
# new: Open new page with action
# play: Pass the uri to the media handler
# queue: Pass the uri to the queueing media handler
# download: Download the media at the uri with the media handler
# Make sure we recieved enough input

echo "JS_ACTION: $1"
if [[ -z "$1" ]]
then
    echo 'No JS_ACTION or SH_ACTION defined. Aborting...'
    exit
fi
JS_ACTION=$1
shift

echo "SH_ACTION: $1"
if [[ -z "$1" ]]
then
    echo 'No SH_ACTION defined. Aborting...'
    exit
fi
SH_ACTION=$1
shift

KEYS_PRESSED=""
echo "KEYS: $1"
if [[ -n "$1" ]]
then
    KEYS_PRESSED="$1"
fi
shift

# If there are no keys pressed yet, we initialize a follow
printf 'js uzbl_follow_data.init_follow("@follow_hint_keys", "'"$JS_ACTION"'")\n' > "$UZBL_FIFO"
if [[ "$KEYS_PRESSED" == "" ]]
then
    exit
fi
FOLLOW_RES="$(printf 'js uzbl_follow_data.update_chars("'"$KEYS_PRESSED"'")\n' | socat - "unix-connect:$UZBL_SOCKET" | tail -n4 | awk '/^-.+:/ {print}')"


echo "FOLLOW_RES: $FOLLOW_RES"
printf '@set_mode\nevent KEYCMD_CLEAR\n' > "$UZBL_FIFO"
exit

# Update our char field - with whatever is in KEYS_PRESSED, get the output
#RESULT_FOLLOW="$( printf 'js uzbl_follow_data.update_chars("'"$KEYS_PRESSED"'")\n' | socat - "unix-connect:$UZBL_SOCKET" | tail -n4 | awk '/^-.+:/ {print}')"

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

