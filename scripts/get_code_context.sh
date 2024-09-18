#!/bin/bash

# Usage instructions
# Run with: ./get_code_context.sh -d "components pages src" -e "js ts py" -i "ico png jpg"
# -d: Directories to include (space-separated)
# -e: File extensions to include (without dot, space-separated)
# -i: File types to ignore (space-separated)

# Default values
default_directories=("src" "lib" "components" "pages" "app")
default_extensions=("js" "ts" "py" "go" "java" "rb" "php")
default_ignore=("ico" "png" "jpg" "jpeg" "gif" "svg")

# Parse options
while getopts d:e:i: flag; do
  case "${flag}" in
  d) directories=(${OPTARG}) ;;     # directories passed by the user
  e) extensions=(${OPTARG}) ;;      # extensions passed by the user
  i) ignore_patterns=(${OPTARG}) ;; # ignore patterns passed by the user
  esac
done

# Use provided or default values
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
        echo "// File: $relative_path" >>"$output_file"
        cat "$entry" >>"$output_file"
        echo "" >>"$output_file"
      fi
    fi
  done
}

# Process the directories
for dir in "${directories[@]}"; do
  if [ -d "${project_dir}/${dir}" ]; then
    read_files "${project_dir}/${dir}"
  fi
done

echo "Code context has been saved to $output_file"
