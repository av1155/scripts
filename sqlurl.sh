#!/bin/bash

# Use fzf to select a .db file in the current working directory
search_directory=$(pwd)
selected_file=$(find "$search_directory" -type f -name "*.db" | fzf)

# Check if a file was selected
if [ -n "$selected_file" ]; then
    # Extract the directory path from the selected file
    db_directory=$(dirname "$selected_file")

    # Define an array of supported database management tools
    supported_tools=("sqlite" "mysql" "postgresql")

    # Display a menu of supported tools for the user to choose from
    echo "Select a database management tool:"
    for ((i = 0; i < ${#supported_tools[@]}; i++)); do
        echo "$((i + 1))) ${supported_tools[i]}"
    done

    # Prompt the user to choose a tool by number or type the name
    read -r -p "Enter the number or name of the database management tool: " db_choice

    # Check if the user entered a number
    if [[ $db_choice =~ ^[0-9]+$ ]]; then
        tool_index=$((db_choice - 1))
        if [ "$tool_index" -ge 0 ] && [ "$tool_index" -lt "${#supported_tools[@]}" ]; then
            db_tool="${supported_tools[$tool_index]}"
        else
            echo "Invalid tool number."
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
        mysql)
            db_url="mysql://username:password@hostname/database"
            # Replace with actual MySQL connection string
            ;;
        postgresql)
            db_url="postgresql://username:password@hostname/database"
            # Replace with actual PostgreSQL connection string
            ;;
        *)
            echo "Unsupported database management tool."
            exit 1
            ;;
    esac

    echo "Selected Database File: $selected_file"
    echo "Database Directory: $db_directory"
    echo "Database Management Tool: $db_tool"
    echo "Database URL: $db_url"
else
    echo "No .db file selected."
    exit 1
fi
