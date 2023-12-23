#!/bin/bash

# Check if a file name is provided
if [ -z "$1" ]; then
	echo "Please provide a file name."
	exit 1
fi

FILE_NAME=$1
CURRENT_DIR=$(pwd)

# AppleScript to open a new iTerm2 window in the current directory and run imgcat
osascript <<EOF
tell application "iTerm2"
    set newWindow to (create window with default profile)
    tell current session of newWindow
        write text "cd '$CURRENT_DIR' && imgcat --width 50% --height 50% -r '$FILE_NAME'"
    end tell
end tell
EOF
