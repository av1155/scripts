#!/bin/bash

# Define colors for output
bold="\033[1m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
red="\033[31m"
cyan="\033[36m"
light_magenta="\033[95m"
reset="\033[0m"

# Display help message
show_help() {
  echo -e "${bold}Usage:${reset} $0 [options]"
  echo ""
  echo -e "${bold}Options:${reset}"
  echo -e "  ${blue}If any arguments are provided instead of the defaults,${reset}"
  echo -e "  ${blue}those will replace the default arguments.${reset}"
  echo -e "  ${yellow}-d${reset}  Directories to include (default: . )"
  echo -e "  ${yellow}-e${reset}  File extensions to include (default: js ts html css py go java c cpp cs rb rs lua php sh zsh md txt)"
  echo -e "  ${yellow}-i${reset}  File types to ignore (default: ico png jpg jpeg gif svg out log tmp dist build .DS_Store __pycache__ swp swo idea coverage env venv Icon?)"
  echo -e "  ${yellow}-n${reset}  Include files without extensions"
  echo -e "  ${yellow}-p${reset}  Patterns for files without extensions (requires -n)"
  echo -e "  ${yellow}-h${reset}  Show this help message"
}

# Default values
default_directories=(".")
default_extensions=("js" "ts" "html" "css" "py" "go" "java" "c" "cpp" "cs" "rb" "rs" "lua" "php" "sh" "zsh" "md" "txt")
default_ignore=("ico" "png" "jpg" "jpeg" "gif" "svg" "out" "log" "tmp" "dist" "build" "DS_Store" "__pycache__" "swp" "swo" "idea" "coverage" "env" "venv" "Icon?")

# Initialize variables for new options
include_no_extension="n"
no_extension_patterns=""

# Initialize arrays with default values
directories=("${default_directories[@]}")
extensions=("${default_extensions[@]}")
ignore_patterns=("${default_ignore[@]}")

# Parse command-line options
interactive=false
while getopts "d:e:i:p:nh" flag; do
  case "${flag}" in
  d) read -r -a directories <<<"${OPTARG}" ;;     # User-provided directories
  e) read -r -a extensions <<<"${OPTARG}" ;;      # User-provided extensions
  i) read -r -a ignore_patterns <<<"${OPTARG}" ;; # User-provided ignore patterns
  n) include_no_extension="y" ;;                  # Include files without extensions
  p) no_extension_patterns="${OPTARG}" ;;         # Patterns for files without extensions
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

# Shift the arguments so that positional parameters start at the right place
shift $((OPTIND - 1))

# If no options are provided, enable interactive mode
if [ $OPTIND -eq 1 ]; then
  interactive=true
fi

# Interactive mode for user input
if [ "$interactive" = true ]; then
  echo -e "${green}Interactive mode: No directories or extensions provided.${reset}"
  echo -e "\n${blue}If any arguments are provided instead of the defaults,${reset}"
  echo -e "${bold}${blue}those will replace the default arguments.${reset}"
  echo -e "${blue}Arguments should be space separated, ex:${reset}"
  echo -e "${blue}        ${red}directory1 directory2 txt java html css${reset}"

  # Prompt for directories
  read -rp "$(echo -e "\n${yellow}• Enter directories to include ${cyan}(default: . ): ${reset}")" input_directories
  read -r -a directories <<<"${input_directories:-${default_directories[@]}}"

  # Prompt for extensions
  read -rp "$(echo -e "${yellow}• Enter file extensions to include ${cyan}(default: js ts html css py go java c cpp cs rb rs lua php sh zsh md txt): ${reset}")" input_extensions
  read -r -a extensions <<<"${input_extensions:-${default_extensions[@]}}"

  # Prompt for ignore patterns
  read -rp "$(echo -e "${yellow}• Enter file types to ignore ${cyan}(default: ico png jpg jpeg gif svg out log tmp dist build .DS_Store __pycache__ swp swo idea coverage env venv Icon?): ${reset}")" input_ignore
  read -r -a ignore_patterns <<<"${input_ignore:-${default_ignore[@]}}"

  # Ask about files without extensions
  read -rp "$(echo -e "${yellow}• Do you want to include files without extensions? [y/N]: ${reset}")" include_no_extension
  if [ "$include_no_extension" == "y" ]; then
    read -rp "$(echo -e "${yellow}• Enter the specific names or patterns for files without extensions to include (or press ${cyan}Enter${yellow} to include all): ${reset}")" no_extension_patterns
  fi

  # Construct the equivalent command
  cmd="./get_code_context.sh"

  if [[ "${directories[*]}" != "${default_directories[*]}" ]]; then
    cmd+=" -d \"${directories[*]}\""
  fi

  if [[ "${extensions[*]}" != "${default_extensions[*]}" ]]; then
    cmd+=" -e \"${extensions[*]}\""
  fi

  if [[ "${ignore_patterns[*]}" != "${default_ignore[*]}" ]]; then
    cmd+=" -i \"${ignore_patterns[*]}\""
  fi

  if [ "$include_no_extension" == "y" ]; then
    cmd+=" -n"
    if [ -n "$no_extension_patterns" ]; then
      cmd+=" -p \"${no_extension_patterns}\""
    fi
  fi

  echo -e "\n${green}Equivalent command:${reset} $cmd"

fi

# Use default values if nothing is provided
directories=("${directories[@]:-${default_directories[@]}}")
extensions=("${extensions[@]:-${default_extensions[@]}}")
ignore_patterns=("${ignore_patterns[@]:-${default_ignore[@]}}")

# Define output file and clean up old file
project_dir=$(pwd)
output_file="${project_dir}/code_context.txt"
[ -f "$output_file" ] && rm "$output_file"

# Clear header to label the tree structure
echo "====================" >"$output_file"
echo "Project Structure:" >>"$output_file"
echo "====================" >>"$output_file"
eza -A --git --icons=auto --tree --level=2 --ignore-glob '.git|node_modules|*.log|*.tmp|dist|build|.DS_Store|__pycache__|*.swp|*.swo|.idea|coverage|env|venv|Icon?' >>"$output_file"

# Add separation for clarity before listing the file contents
echo -e "\n====================" >>"$output_file"
echo "File Contents:" >>"$output_file"
echo -e "====================\n" >>"$output_file"

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
  echo -e "\n${bold}${light_magenta}Constructed fd command (extensions):${reset} $fd_command_ext"

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
    echo -e "${bold}${light_magenta}Constructed fd command (no extensions):${reset} $fd_command_no_ext"

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
  echo -e "\n${green}Code context has been saved to $output_file${reset}\n"
else
  echo -e "${red}No files were found based on the input. Code context not generated.${reset}\n"
fi
