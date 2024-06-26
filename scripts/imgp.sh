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
		-path './.Trash' -prune -o \
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

# Function to run imgcat for iTerm2
run_imgcat_iterm2() {
	osascript <<EOF
tell application "iTerm2"
    set newWindow to (create window with default profile)
    tell current session of newWindow
        write text "cd '$CURRENT_DIR' && imgcat --width 80% --height 80% -r '$FILE_NAME'"
    end tell
end tell
EOF
}

# Function to run icat for Kitty
run_icat_kitty() {
	# Get the size of the terminal
	local cols
	cols=$(tput cols)

	local lines
	lines=$(tput lines)

	# Calculate 80% of the terminal size
	local width=$((cols * 60 / 100))
	local height=$((lines * 60 / 100))

	# Place the image to occupy 60% of the terminal, centered
	local place_string="${width}x${height}@10x15"

	# Run icat with the calculated dimensions and scale-up option
	kitty +kitten icat --clear --place "$place_string" --scale-up "$FILE_NAME"
}

# Function to display image using viu with block output in tmux
run_viu_tmux() {
	if [ -f "$FILE_NAME" ]; then
		# Get the terminal size
		local cols
		cols=$(tput cols)

		local lines
		lines=$(tput lines)

		# Calculate 60% of the terminal size
		local width=$((cols * 60 / 100))
		local height=$((lines * 60 / 100))

		# Display the image with viu, resized to 60% of the terminal dimensions and force block output
		viu -w "$width" -h "$height" -b "$FILE_NAME"
	else
		echo "File not found: $FILE_NAME"
		exit 1
	fi
}

# Function to display image using viu with resized dimensions
run_viu_generic() {
	if [ -f "$FILE_NAME" ]; then
		# Get the terminal size
		local cols
		cols=$(tput cols)

		local lines
		lines=$(tput lines)

		# Calculate 60% of the terminal size
		local width=$((cols * 60 / 100))
		local height=$((lines * 60 / 100))

		# Display the image with viu, resized to 60% of the terminal dimensions
		viu -w "$width" -h "$height" "$FILE_NAME" -b
	else
		echo "File not found: $FILE_NAME"
		exit 1
	fi
}

# If Kitty is installed and we're not in tmux, attempt to run in Kitty
if command -v kitty &>/dev/null && [ -z "$TMUX" ]; then
	run_icat_kitty 2>/dev/null && exit 0
fi

# If we're running inside tmux
if [ -n "$TMUX" ]; then
	run_viu_tmux && exit 0
fi

# If iTerm2 is installed, attempt to run in iTerm2
if command -v osascript &>/dev/null && [[ -f "$HOME/.iterm2/imgcat" ]]; then
	run_imgcat_iterm2 2>/dev/null && exit 0
fi

# Fallback to using viu if no other terminal-specific function worked
run_viu_generic && exit 0

echo "Unsupported terminal. This script supports iTerm2, Kitty, tmux, and other terminals via viu."
