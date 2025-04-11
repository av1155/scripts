#!/bin/bash

# Define colors
bold="\033[1m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
red="\033[31m"
light_magenta="\033[95m"
reset="\033[0m"

# Display help
show_help() {
  echo -e "${bold}Usage:${reset} $0 [options]"
  echo ""
  echo -e "${bold}Options:${reset}"
  echo -e "  ${yellow}-d${reset}  Directories to include (default: . )"
  echo -e "  ${yellow}-e${reset}  File extensions to include (default: js ts tsx html css py go java c cpp cs rb rs lua php sh zsh md txt)"
  echo -e "  ${yellow}-i${reset}  File types to ignore (default: ico png jpg jpeg gif svg out log tmp dist build .DS_Store __pycache__ jar swp swo idea coverage env venv Icon?)"
  echo -e "  ${yellow}-x${reset}  Directories to exclude from search"
  echo -e "  ${yellow}-n${reset}  Include files without extensions"
  echo -e "  ${yellow}-p${reset}  Patterns for files without extensions (requires -n)"
  echo -e "  ${yellow}-o${reset}  Output file name (default: code_context.txt)"
  echo -e "  ${yellow}-h${reset}  Show this help message"
}

# Defaults
default_directories=(".")
default_extensions=("js" "ts" "tsx" "html" "css" "py" "go" "java" "c" "cpp" "cs" "rb" "rs" "lua" "php" "sh" "zsh" "md" "txt")
default_ignore=("ico" "png" "jpg" "jpeg" "gif" "svg" "out" "log" "tmp" "dist" "build" "DS_Store" "__pycache__" "jar" "swp" "swo" "idea" "coverage" "env" "venv" "Icon?")
output_file="code_context.txt"

include_no_extension="n"
no_extension_patterns=""

# Initialize with defaults
directories=("${default_directories[@]}")
extensions=("${default_extensions[@]}")
ignore_patterns=("${default_ignore[@]}")
excluded_directories=()
interactive=false

# Parse options
while getopts "d:e:i:x:p:o:nh" flag; do
  case "${flag}" in
  d) IFS=' ' read -ra directories <<<"${OPTARG}" ;;
  e) IFS=' ' read -ra extensions <<<"${OPTARG}" ;;
  i) IFS=' ' read -ra ignore_patterns <<<"${OPTARG}" ;;
  x) IFS=' ' read -ra excluded_directories <<<"${OPTARG}" ;;
  o) output_file="${OPTARG}" ;;
  n) include_no_extension="y" ;;
  p) no_extension_patterns="${OPTARG}" ;;
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

shift $((OPTIND - 1))

if [ $OPTIND -eq 1 ]; then
  interactive=true
fi

# Interactive fallback
if [ "$interactive" = true ]; then
  echo -e "${green}Interactive mode: No options were provided.${reset}"

  read -rp "$(echo -e "${yellow}• Directories to include (default: .): ${reset}")" input_directories
  IFS=' ' read -ra directories <<<"${input_directories:-${default_directories[*]}}"

  read -rp "$(echo -e "${yellow}• File extensions to include (default: ${default_extensions[*]}): ${reset}")" input_extensions
  IFS=' ' read -ra extensions <<<"${input_extensions:-${default_extensions[*]}}"

  read -rp "$(echo -e "${yellow}• File types to ignore (default: ${default_ignore[*]}): ${reset}")" input_ignore
  IFS=' ' read -ra ignore_patterns <<<"${input_ignore:-${default_ignore[*]}}"

  read -rp "$(echo -e "${yellow}• Directories to exclude (optional): ${reset}")" input_excluded
  IFS=' ' read -ra excluded_directories <<<"${input_excluded}"

  read -rp "$(echo -e "${yellow}• Include files without extensions? [y/N]: ${reset}")" include_no_extension
  if [ "$include_no_extension" == "y" ]; then
    read -rp "$(echo -e "${yellow}• Patterns for no-extension files (optional): ${reset}")" no_extension_patterns
  fi

  # Print suggested rerun command
  rerun_cmd=("getc")
  [ -n "${directories[*]}" ] && rerun_cmd+=("-d" "\"${directories[*]}\"")
  [ -n "${extensions[*]}" ] && rerun_cmd+=("-e" "\"${extensions[*]}\"")
  [ -n "${ignore_patterns[*]}" ] && rerun_cmd+=("-i" "\"${ignore_patterns[*]}\"")
  [ -n "${excluded_directories[*]}" ] && rerun_cmd+=("-x" "\"${excluded_directories[*]}\"")
  [ "$include_no_extension" == "y" ] && rerun_cmd+=("-n")
  [ -n "$no_extension_patterns" ] && rerun_cmd+=("-p" "\"$no_extension_patterns\"")
  [ "$output_file" != "code_context.txt" ] && rerun_cmd+=("-o" "\"$output_file\"")

  echo -e "\n${blue}Rerun with:${reset} ${bold}${rerun_cmd[*]}${reset}\n"

fi

# Output file prep
project_dir=$(pwd)
output_path="${project_dir}/${output_file}"
[ -f "$output_path" ] && rm "$output_path"

{
  echo "===================="
  echo "Project Structure:"
  echo "===================="
} | tee -a "$output_path" >/dev/null

{
  eza -A --git --icons=auto --tree --level=3 \
    --ignore-glob '.git|.idea|__pycache__|node_modules|dist|build|*.log|*.tmp|*.swp|*.swo|*.ttf|coverage|env|venv|Icon?|.DS_Store'
} | tee -a "$output_path" >/dev/null

{
  echo -e "\n===================="
  echo "File Contents:"
  echo -e "====================\n"
} | tee -a "$output_path" >/dev/null

# Timer
start_time=$(date +%s.%N)

# Search and extract
for dir in "${directories[@]}"; do
  if [ ! -d "$dir" ]; then
    echo -e "${red}Warning:${reset} Directory '$dir' does not exist. Skipping."
    continue
  fi

  # With extension
  fd_args=(--hidden --type f)
  for ext in "${extensions[@]}"; do
    fd_args+=(--extension "$ext")
  done
  for ignore in "${ignore_patterns[@]}"; do
    skip=false
    for ext in "${extensions[@]}"; do
      if [[ "$ignore" == "$ext" ]]; then
        skip=true
        break
      fi
    done
    if [[ $skip == false ]]; then
      fd_args+=(--exclude "*.$ignore")
    fi
  done

  for xdir in "${excluded_directories[@]}"; do
    fd_args+=(--exclude "$xdir")
  done

  echo -e "${bold}${light_magenta}\nScanning files with extensions in $dir...${reset}"

  (
    cd "$dir" || exit
    fd "${fd_args[@]}" . | while IFS= read -r file; do
      {
        echo ""
        echo "//===FILE_START=== $dir/$file"
        cat "$file"
        echo ""
        echo "//===FILE_END==="
        echo ""
      } | tee -a "$output_path" >/dev/null
    done
  )

  # Without extension
  if [ "$include_no_extension" == "y" ]; then
    echo -e "${bold}${light_magenta}Scanning files without extensions in $dir...${reset}"

    (
      cd "$dir" || exit
      fd_noext_args=(--hidden --type f)

      for ignore in "${ignore_patterns[@]}"; do
        skip=false
        for ext in "${extensions[@]}"; do
          if [[ "$ignore" == "$ext" ]]; then
            skip=true
            break
          fi
        done
        if [[ $skip == false ]]; then
          fd_noext_args+=(--exclude "*.$ignore")
        fi
      done

      for xdir in "${excluded_directories[@]}"; do
        fd_noext_args+=(--exclude "$xdir")
      done

      if [ -z "$no_extension_patterns" ]; then
        fd_noext_args+=(--regex '^[^.]+$')
      else
        IFS=' ' read -ra patterns <<<"$no_extension_patterns"
        regex=$(
          IFS='|'
          echo "^(${patterns[*]})$"
        )
        fd_noext_args+=(--regex "$regex")
      fi

      fd "${fd_noext_args[@]}" . | while IFS= read -r file; do
        {
          echo ""
          echo "//===FILE_START=== $dir/$file"
          cat "$file"
          echo ""
          echo "//===FILE_END==="
          echo ""
        } | tee -a "$output_path" >/dev/null
      done
    )
  fi
done

# Done
echo -e "\n${green}Code context saved to ${output_path}${reset}"
end_time=$(date +%s.%N)
elapsed=$(awk "BEGIN {print $end_time - $start_time}")
printf "${blue}Execution time:${reset} %.3fs\n" "$elapsed"
