#!/bin/bash

# Get the status of the player
STATUS=$(playerctl --player=spotify status)

# Function for metadata
getmeta (){
    playerctl --player=spotify metadata --format "{{ $1 }}"
}
# Function for track duration
getduration (){
    playerctl metadata --format "{{ duration($1) }}"
}

# Variables for format
ARTIST=$(getmeta artist)
TITLE=$(getmeta title)
ALBUM=$(getmeta album)
LENGTH=$(getduration mpris:length)
POSITION=$(getduration position)
FORMAT="$ARTIST - $ALBUM"
DURATION="$POSITION/$LENGTH"

# Icons for format
# Different icons for play pause states
if [[ $STATUS == "Playing" ]]; then
    ICON_TOGGLE=""
elif [[ $STATUS == "Paused" ]]; then
    ICON_TOGGLE=""
else
    ICON_TOGGLE=""
fi
echo ${ICON_STR[@]}
echo ${ICON_HEX[@]}
ICON_STOP=""
ICON_PREV=""
ICON_NEXT=""
ICON_BACKWARD=""
ICON_FORWARD=""
ICON_SHUFFLE="󰒝"
ICON_REPEAT="󰑖"
# Order of icons
ICON_FORMAT="$ICON_TOGGLE\n$ICON_BACKWARD\n$ICON_FORWARD\n$ICON_PREV\n$ICON_NEXT\n$ICON_REPEAT\n$ICON_SHUFFLE\n$ICON_STOP"

# Check for shuffle
SHUFFLE_STATUS=$(playerctl --player=spotify shuffle)
if [[ $SHUFFLE_STATUS == "On" ]]; then
    active="-a 6"
elif [[ $SHUFFLE_STATUS == "Off" ]]; then
    urgent="-u 6"
else
    echo "Unexpected shuffle case"
fi

# Check for repeat
REPEAT_STATUS=$(playerctl --player=spotify loop)
if [[ $REPEAT_STATUS == "Track" || $REPEAT_STATUS == "Playlist" ]]; then
    [ -n "$active" ] && active+=",5" || active="-a 5"
elif [[ $REPEAT_STATUS == "None" ]]; then
    [ -n "$urgent" ] && urgent+=",5" || urgent="-u 5"
else
    echo "Unexpected loop check case"
fi

# Run rofi function
rofi_run_playing (){
    printf $1 | rofi -dmenu \
                     -p "$FORMAT" \
                     -theme-str "entry { enabled: false;}" \
                     -theme-str 'textbox-prompt-colon { str: "󰎈";}' \
                     -theme-str 'textbox-prompt-colon { background-color: @active;}' \
                     -theme-str "listview {columns: 8; lines: 1;}" \
                     -mesg "$TITLE :: $DURATION" \
		                 ${active} ${urgent} \
		                 -theme "$HOME/projects/rofi-spotify/spotify.rasi"
}
rofi_run_paused (){
    printf $1 | rofi -dmenu \
                     -p "$FORMAT" \
                     -theme-str "entry { enabled: false;}" \
                     -theme-str 'textbox-prompt-colon { str: "󰎊";}' \
                     -theme-str 'textbox-prompt-colon { background-color: @urgent;}' \
                     -theme-str 'prompt { background-color: @urgent;}' \
                     -theme-str "listview {columns: 8; lines: 1;}" \
                     -mesg "$TITLE :: $DURATION" \
		                 ${active} ${urgent} \
		                 -theme "$HOME/projects/rofi-spotify/spotify.rasi"
}

ICON_YES=""
ICON_NO=""
NO_PLAYER_RUNNING_FORMAT="$ICON_YES\n$ICON_NO"

# No player running
confirm_cmd() {
	  printf $1 | rofi -dmenu \
		                 -p 'Confirmation' \
		                 -mesg 'Spotify Is Not Currently Active. Would You Like To Open Spotify?' \
		                 -theme confirm.rasi
}


# Function for easier player actions
player_action (){
    playerctl --player=spotify $1
}

# Evaluate output
echo $STATUS
if [[ $STATUS == "Playing" ]]; then
    OUTPUT=$(rofi_run_playing $ICON_FORMAT)
elif [[ $STATUS == "Paused" ]]; then
    OUTPUT=$(rofi_run_paused $ICON_FORMAT)
else
    OUTPUT=$(confirm_cmd $NO_PLAYER_RUNNING_FORMAT)
fi
echo $OUTPUT
if [[ $OUTPUT == $ICON_TOGGLE ]]; then
    player_action play-pause
elif [[ $OUTPUT == $ICON_BACKWARD ]]; then
    player_action "position 10-"
elif [[ $OUTPUT == $ICON_FORWARD ]];then
     player_action "position 10+"
elif [[ $OUTPUT == $ICON_PREV ]]; then
    player_action previous
elif [[ $OUTPUT == $ICON_NEXT ]]; then
    player_action next
elif [[ $OUTPUT == $ICON_REPEAT ]]; then
    LOOP_STATUS=$(player_action loop)
    if [[ $LOOP_STATUS == "Track" || $LOOP_STATUS == "Playlist" ]]; then
        player_action "loop none"
    elif [[ $LOOP_STATUS == "None" ]]; then
        player_action "loop Track"
    else
        echo "Unexpected loop case"
    fi
elif [[ $OUTPUT == $ICON_SHUFFLE ]]; then
    player_action "shuffle toggle"
elif [[ $OUTPUT == $ICON_STOP ]]; then
    player_action stop
elif [[ $OUTPUT == $ICON_YES ]]; then
    spotify
elif [[ $OUTPUT == $ICON_NO ]]; then
    echo "Script exited"
    exit
fi
