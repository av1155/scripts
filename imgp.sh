#!/bin/bash

# Default values
MAX_DEPTH=7
FILE_NAME=""

# Usage function with detailed help message
usage() {
	echo "Usage: imgp [-d DEPTH] [-f \"FILENAME\"]"
	echo "Options:"
	echo "  -d, --depth      Set the max depth for searching files (default is 7)"
	echo "  -f, --filename   Specify a filename for direct selection"
	echo "  -h, --help       Display this help message"
	echo ""
	echo "Example: imgp -d 5"
	echo "Example: imgp -f \"picture.png\""
	exit 1
}

# Function to check for required commands
check_commands() {
	if ! command -v fzf >/dev/null 2>&1 || ! command -v bat >/dev/null 2>&1; then
		echo "Required commands 'fzf' and/or 'bat' not found. Please ensure both fzf and bat are installed."
		exit 1
	fi

	if [ ! -f "$HOME/.iterm2/imgcat" ]; then
		echo "imgcat script not found at '$HOME/.iterm2/imgcat'. Please ensure it is installed and accessible."
		exit 1
	fi
}

# Function for file selection using fzf
file_selection() {
	FILE_NAME=$(find . -maxdepth "$MAX_DEPTH" \
		-path '*/.git' -prune -o \
		-path './Library' -prune -o \
		-path '*/node_modules' -prune -o \
		-path '*/build' -prune -o \
		-path '*/dist' -prune -o \
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
		\) -print | fzf --preview '[[ -d {} ]] || bat --color=always {}' --preview-window bottom:30% --prompt="Select a file: ")
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
	case $1 in
	-d | --depth)
		if [[ $2 =~ ^[0-9]+$ ]]; then
			MAX_DEPTH="$2"
		else
			echo "Depth must be a positive integer."
			echo ""
			usage
		fi
		shift
		;;
	-f | --filename)
		FILE_NAME="$2"
		shift
		;;
	-h | --help) usage ;;
	*)
		echo "Unknown parameter passed: $1"
		usage
		;;
	esac
	shift
done

# Check for required commands
check_commands

# If FILE_NAME is not provided, use fzf to select
[ -z "$FILE_NAME" ] && file_selection

# Exit if no file was selected or provided
[ -z "$FILE_NAME" ] && {
	echo "No file selected or provided."
	exit 1
}

CURRENT_DIR=$(pwd)

# AppleScript to open a new iTerm2 window and run imgcat with the selected file
osascript <<EOF
tell application "iTerm2"
    set newWindow to (create window with default profile)
    tell current session of newWindow
        write text "cd '$CURRENT_DIR' && imgcat --width 80% --height 80% -r '$FILE_NAME'"
    end tell
end tell
EOF

# Execute imgcat function
run_imgcat
