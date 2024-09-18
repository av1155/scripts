#!/bin/bash

bold="\033[1m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
red="\033[31m"
orange="\033[38;5;208m"
reset="\033[0m"

# Function to display help message
show_help() {
  echo -e "${bold}Usage:${reset} $0 [options]"
  echo ""
  echo -e "${bold}Options:${reset}"
  echo -e "  ${yellow}-d${reset}   Directories to include (space-separated, default: ${blue}src lib components pages app${reset})"
  echo -e "  ${yellow}-e${reset}   File extensions to include (space-separated, default: ${blue}js ts py go java rb php${reset})"
  echo -e "  ${yellow}-i${reset}   File types to ignore (space-separated, default: ${blue}ico png jpg jpeg gif svg${reset})"
  echo -e "  ${yellow}-h${reset}   Show help message"
  echo ""
  echo -e "${bold}Examples:${reset}"
  echo -e "  $0 -d \"${blue}src test${reset}\" -e \"${blue}py html${reset}\" -i \"${blue}png jpg${reset}\""
  echo -e "  $0 -d \"${blue}application migrations static templates${reset}\" -e \"${blue}py html yaml yml${reset}\" -i \"${blue}png jpg gif${reset}\""
}

# Default values
default_directories=("src" "lib" "components" "pages" "app")
default_extensions=("js" "ts" "py" "go" "java" "rb" "php")
default_ignore=("ico" "png" "jpg" "jpeg" "gif" "svg")

# Parse options
interactive=false
while getopts "d:e:i:h" flag; do
  case "${flag}" in
  d) read -r -a directories <<<"${OPTARG}" ;;     # directories passed by the user
  e) read -r -a extensions <<<"${OPTARG}" ;;      # extensions passed by the user
  i) read -r -a ignore_patterns <<<"${OPTARG}" ;; # ignore patterns passed by the user
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

# Interactive prompts for directories and extensions
if [ "$interactive" = true ]; then
  echo -e "${green}Interactive mode: No directories or extensions provided.${reset}"

  # Prompt for directories
  read -rp "$(echo -e "${yellow}Enter directories to include (space-separated, default: src lib components pages app): ${reset}") " input_directories
  read -r -a directories <<<"${input_directories:-${default_directories[@]}}"

  # Prompt for extensions
  read -rp "$(echo -e "${yellow}Enter file extensions to include (space-separated, default: js ts py go java rb php): ${reset}") " input_extensions
  read -r -a extensions <<<"${input_extensions:-${default_extensions[@]}}"

  # Prompt for ignore patterns
  read -rp "$(echo -e "${yellow}Enter file types to ignore (space-separated, default: ico png jpg jpeg gif svg): ${reset}") " input_ignore
  read -r -a ignore_patterns <<<"${input_ignore:-${default_ignore[@]}}"

  # Generate the command the user just configured interactively
  echo ""
  echo -e "${blue}You can run the following command to achieve the same result next time:${reset}"
  echo -e "${bold}./get_code_context.sh -d \"${directories[*]}\" -e \"${extensions[*]}\" -i \"${ignore_patterns[*]}\"${reset}"
  echo ""
fi

# Use provided or default values if no input is given
directories=("${directories[@]:-${default_directories[@]}}")
extensions=("${extensions[@]:-${default_extensions[@]}}")
ignore_patterns=("${ignore_patterns[@]:-${default_ignore[@]}}")

# Project directory and output file
project_dir=$(pwd)
output_file="${project_dir}/code_context.txt"

# Remove output file if it exists
if [ -f "$output_file" ]; then
  rm "$output_file"
fi

# Function to check if a file extension should be ignored
should_ignore_file() {
  local file_ext="${1##*.}"
  for ignore in "${ignore_patterns[@]}"; do
    if [[ "$file_ext" == "$ignore" ]]; then
      return 0 # true (should ignore)
    fi
  done
  return 1 # false (should not ignore)
}

# Function to check if a file should be included
should_include_file() {
  local file_ext="${1##*.}"
  for ext in "${extensions[@]}"; do
    if [[ "$file_ext" == "$ext" ]]; then
      return 0 # true (should include)
    fi
  done
  return 1 # false (should not include)
}

# Recursive function to read files and append their content
read_files() {
  for entry in "$1"/*; do
    if [ -d "$entry" ]; then
      # If it's a directory, recurse into it
      read_files "$entry"
    elif [ -f "$entry" ]; then
      if should_ignore_file "$entry"; then
        continue
      fi

      if should_include_file "$entry"; then
        relative_path="${entry#"$project_dir/"}"
        {
          echo "// File: $relative_path"
          cat "$entry"
          echo ""
        } >>"$output_file"
      fi
    fi
  done
}

# Process the directories
echo -e "${blue}Processing directories:${reset} ${orange}${directories[*]}${reset}"
echo -e "${blue}Looking for file extensions:${reset} ${orange}${extensions[*]}${reset}"
echo -e "${blue}Ignoring file types:${reset} ${orange}${ignore_patterns[*]}${reset}"

for dir in "${directories[@]}"; do
  if [ -d "${project_dir}/${dir}" ]; then
    read_files "${project_dir}/${dir}"
  fi
done

echo -e "${green}Code context has been saved to $output_file${reset}\n"
