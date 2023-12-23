#!/bin/bash

# Check for fzf and use it to select a file if it's available
if command -v fzf >/dev/null 2>&1; then

    FILE_NAME=$(find . \( \
            -type d -o \
            -type f \( \
            -name "*.jpg" -o \
            -name "*.jpeg" -o \
            -name "*.png" -o \
            -name "*.gif" -o \
            -name "*.webp" -o \
            -name "*.tiff" -o \
            -name "*.bmp" -o \
            -name "*.heif" -o \
            -name "*.avif" -o \
            -name "*.jfif" -o \
            -name "*.pnm" -o \
            -name "*.svg" -o \
            -name "*.psd" -o \
            -name "*.raw" -o \
            -name "*.exr" -o \
            -name "*.ico" -o \
            -name "*.pcx" -o \
            -name "*.tga" -o \
            -name "*.dng" -o \
            -name "*.ai" -o \
            -name "*.eps" -o \
            -name "*.ps" -o \
            -name "*.xcf" -o \
            -name "*.cdr" -o \
            -name "*.flif" -o \
            -name "*.bpg" -o \
            -name "*.apng" -o \
            -name "*.jxl" -o \
            -name "*.raf" -o \
            -name "*.nef" -o \
            -name "*.orf" -o \
            -name "*.srw" -o \
            -name "*.cr2" -o \
            -name "*.crw" -o \
            -name "*.dcr" \
            \) \
        \) | fzf --preview '[[ -d {} ]] || bat --color=always {}' --preview-window right:50%:noborder --prompt="Select a file or directory: ")
else
    # Fall back to manual file name input if fzf is not installed
    echo "fzf not found. Please provide a file name."
    read -r FILE_NAME
fi

# Exit if no file was selected or provided
if [ -z "$FILE_NAME" ]; then
    echo "No file selected."
    exit 1
fi

CURRENT_DIR=$(pwd)

# AppleScript to open a new iTerm2 window and run imgcat with the selected file
osascript <<EOF
tell application "iTerm2"
    set newWindow to (create window with default profile)
    tell current session of newWindow
        write text "cd '$CURRENT_DIR' && imgcat --width 70% --height 70% -r '$FILE_NAME'"
    end tell
end tell
EOF
