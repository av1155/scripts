#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
ORANGE='\033[38;5;209m'
NC='\033[0m' # No Color

# Function to prompt user for database connection details
get_db_details() {
	read -r -p "Enter username: " username
	read -r -p "Enter password: " -s password
	echo
	read -r -p "Enter hostname: " hostname
	read -r -p "Enter port (Press Enter for default): " port
	read -r -p "Enter database name/service name: " dbname
}

# Use fzf to select a .db file in the current working directory
search_directory=$(pwd)
selected_file=$(find "$search_directory" -type d \( -name ".git" -o -name "Library" -o -name "Applications" \) -prune -o -type f -name "*.db" -print | fzf)

# Check if a file was selected
if [ -n "$selected_file" ]; then
	# Extract the directory path from the selected file
	db_directory=$(dirname "$selected_file")

	# Define an array of supported database management tools
	supported_tools=("sqlite" "mysql" "postgresql" "mssql" "oracle" "mongodb")

	# Display a menu of supported tools for the user to choose from
	echo -e "${YELLOW}Select a database management tool:${NC}"
	for ((i = 0; i < ${#supported_tools[@]}; i++)); do
		echo -e "${GREEN}$((i + 1))) ${supported_tools[i]}${NC}"
	done

	# Prompt the user to choose a tool by number or type the name
	read -r -p "Enter the number or name of the database management tool: " db_choice

	# Check if the user entered a number
	if [[ $db_choice =~ ^[0-9]+$ ]]; then
		tool_index=$((db_choice - 1))
		if [ "$tool_index" -ge 0 ] && [ "$tool_index" -lt "${#supported_tools[@]}" ]; then
			db_tool="${supported_tools[$tool_index]}"
		else
			echo -e "${RED}Invalid tool number.${NC}"
			exit 1
		fi
	else
		# User entered a tool name directly
		db_tool="$db_choice"
	fi

	# Check which tool was chosen and construct the URL accordingly
	case "$db_tool" in
	sqlite)
		db_url="sqlite://$selected_file"
		;;
	mysql | postgresql | mssql | oracle | mongodb)
		get_db_details
		# Handle the port and password display
		port_part=""
		if [ -n "$port" ]; then
			port_part=":$port"
		fi
		password_part=":********" # Mask the password for display
		if [ -z "$password" ]; then
			password_part=""
		fi
		db_url="${db_tool}://${username}${password_part}@${hostname}${port_part}/${dbname}"
		;;
	*)
		echo -e "${RED}Unsupported database management tool.${NC}"
		exit 1
		;;
	esac

	echo -e "${BLUE}Selected Database File: $selected_file${NC}"
	echo -e "${BLUE}Database Directory: $db_directory${NC}"
	echo -e "${BLUE}Database Management Tool: $db_tool${NC}"
	echo -e "${BLUE}Database URL: ${ORANGE}$db_url${NC}"
else
	echo -e "${RED}No .db file selected.${NC}"
	exit 1
fi
