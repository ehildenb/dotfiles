#!/bin/zsh

# If the first argument exists and says that history is disabled, exit
[[ -z "$1" || "$1" == "0" ]] && exit
shift

source "$UZBL_UTIL_DIR/uzbl-dir.sh"

>> "$UZBL_HISTORY_FILE" || exit 1

# Inject the current URI and any URIs that are passed in as well
HIST_INJECT=("$UZBL_URI" $@)

for HIST_URI in ${HIST_INJECT[@]}
do
    echo "$( date +'%Y-%m-%d %H:%M:%S' ) $HIST_URI $UZBL_TITLE" >> "$UZBL_HISTORY_FILE"
done
