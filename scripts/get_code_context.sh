#!/bin/bash

# Define colors for output
bold="\033[1m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
red="\033[31m"
reset="\033[0m"

# Display help message
show_help() {
  echo -e "${bold}Usage:${reset} $0 [options]"
  echo ""
  echo -e "${bold}Options:${reset}"
  echo -e "  ${yellow}-d${reset}  Directories to include (default: src lib components pages app)"
  echo -e "  ${yellow}-e${reset}  File extensions to include (default: js ts py go java rb php sh zsh md txt)"
  echo -e "  ${yellow}-i${reset}  File types to ignore (default: ico png jpg jpeg gif svg out)"
  echo -e "  ${yellow}-h${reset}  Show this help message"
}

# Default values
default_directories=("src" "lib" "components" "pages" "app")
default_extensions=("js" "ts" "py" "go" "java" "rb" "php" "sh" "zsh" "md" "txt")
default_ignore=("ico" "png" "jpg" "jpeg" "gif" "svg" "out")

# Parse command-line options
interactive=false
while getopts "d:e:i:h" flag; do
  case "${flag}" in
  d) read -r -a directories <<<"${OPTARG}" ;;     # User-provided directories
  e) read -r -a extensions <<<"${OPTARG}" ;;      # User-provided extensions
  i) read -r -a ignore_patterns <<<"${OPTARG}" ;; # User-provided ignore patterns
  h)
    show_help
    exit 0
    ;;
  *)
    echo -e "${red}Invalid option. Use -h for help.${reset}"
    exit 1
    ;;
  esac
done

# If no directories or extensions are provided, enable interactive mode
if [ ${#directories[@]} -eq 0 ] || [ ${#extensions[@]} -eq 0 ]; then
  interactive=true
fi

# Interactive mode for user input
if [ "$interactive" = true ]; then
  echo -e "${green}Interactive mode: No directories or extensions provided.${reset}"

  # Prompt for directories
  read -rp "$(echo -e "${yellow}Enter directories to include (default: src lib components pages app): ${reset}")" input_directories
  read -r -a directories <<<"${input_directories:-${default_directories[@]}}"

  # Prompt for extensions
  read -rp "$(echo -e "${yellow}Enter file extensions to include (default: js ts py go java rb php sh zsh md txt): ${reset}")" input_extensions
  read -r -a extensions <<<"${input_extensions:-${default_extensions[@]}}"

  # Prompt for ignore patterns
  read -rp "$(echo -e "${yellow}Enter file types to ignore (default: ico png jpg jpeg gif svg out): ${reset}")" input_ignore
  read -r -a ignore_patterns <<<"${input_ignore:-${default_ignore[@]}}"

  # Ask about files without extensions
  read -rp "$(echo -e "${yellow}Do you want to include files without extensions? (y/n): ${reset}")" include_no_extension
  if [ "$include_no_extension" == "y" ]; then
    read -rp "$(echo -e "${yellow}Enter the specific names or patterns for files without extensions to include (or press Enter to include all): ${reset}")" no_extension_patterns
  fi
fi

# Use default values if nothing is provided
directories=("${directories[@]:-${default_directories[@]}}")
extensions=("${extensions[@]:-${default_extensions[@]}}")
ignore_patterns=("${ignore_patterns[@]:-${default_ignore[@]}}")

# Define output file and clean up old file
project_dir=$(pwd)
output_file="${project_dir}/code_context.txt"
[ -f "$output_file" ] && rm "$output_file"

# Start file content section
echo -e "${green}Generating project structure...${reset}"

# Process each directory
for dir in "${directories[@]}"; do
  if [ ! -d "$dir" ]; then
    echo "Warning: Directory '$dir' does not exist and will be skipped."
    continue
  fi

  # Construct fd command for files with extensions
  fd_command_ext="fd --type f"

  # Add extensions to the fd command
  for ext in "${extensions[@]}"; do
    fd_command_ext+=" --extension $ext"
  done

  # Add ignored patterns
  for ignore in "${ignore_patterns[@]}"; do
    fd_command_ext+=" --exclude '*.$ignore'"
  done

  # Add directory to process
  fd_command_ext+=" $dir"

  # Debugging: Show constructed fd command for extensions
  echo -e "${yellow}Constructed fd command (extensions):${reset} $fd_command_ext"

  # Execute the fd command for files with extensions
  eval "$fd_command_ext" | while read -r file; do
    relative_path="${file#"$project_dir/"}"
    echo "// File: $relative_path" >>"$output_file"
    cat "$file" >>"$output_file"
    echo "" >>"$output_file"
  done

  # If including files without extensions
  if [ "$include_no_extension" == "y" ]; then
    fd_command_no_ext="fd --type f"

    # Add ignored patterns
    for ignore in "${ignore_patterns[@]}"; do
      fd_command_no_ext+=" --exclude '*.$ignore'"
    done

    # Handle files without extensions
    if [ -z "$no_extension_patterns" ]; then
      fd_command_no_ext+=" --regex '^[^.]+$'" # Match any file without extensions
    else
      # Build regex from user-provided patterns
      regex_patterns=()
      read -r -a patterns <<<"$no_extension_patterns"
      for pattern in "${patterns[@]}"; do
        regex_patterns+=("^$pattern$")
      done
      # Combine regex patterns
      regex_pattern=$(printf "|%s" "${regex_patterns[@]}")
      regex_pattern="${regex_pattern:1}" # Remove leading '|'
      fd_command_no_ext+=" --regex '$regex_pattern'"
    fi

    # Add directory to process
    fd_command_no_ext+=" $dir"

    # Debugging: Show constructed fd command for files without extensions
    echo -e "${yellow}Constructed fd command (no extensions):${reset} $fd_command_no_ext"

    # Execute the fd command for files without extensions
    eval "$fd_command_no_ext" | while read -r file; do
      relative_path="${file#"$project_dir/"}"
      echo "// File: $relative_path" >>"$output_file"
      cat "$file" >>"$output_file"
      echo "" >>"$output_file"
    done
  fi
done

# Check if output file was created
if [ -f "$output_file" ] && [ -s "$output_file" ]; then
  echo -e "${green}Code context has been saved to $output_file${reset}\n"
else
  echo -e "${red}No files were found based on the input. Code context not generated.${reset}\n"
fi
