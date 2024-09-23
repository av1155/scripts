#!/bin/zsh

# Disable the 'nomatch' option so that ls *.c doesn't throw an error if no .c files are found
setopt +o nomatch

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No color

# Function to show LLDB TL;DR commands
show_lldb_tldr() {
    echo -e "${CYAN}====================================================================${NC}"
    echo -e "${YELLOW}TL;DR: Basic LLDB Debugging Commands${NC}"
    echo -e "${CYAN}====================================================================${NC}"
    echo -e "${WHITE}(lldb) breakpoint set --name main  ${NC}# Set a breakpoint at the main function"
    echo -e "${WHITE}(lldb) run                         ${NC}# Run the program"
    echo -e "${WHITE}(lldb) next                        ${NC}# Step to the next line of code"
    echo -e "${WHITE}(lldb) print var                   ${NC}# Print the value of the variable 'var'"
    echo -e "${WHITE}(lldb) exit                        ${NC}# Exit"
    echo -e "${CYAN}====================================================================${NC}"
}

# Check if fzf is installed
if ! command -v fzf &>/dev/null; then
    echo -e "${RED}fzf is not installed. Please install fzf to use this script.${NC}"
    exit 1
fi

# Get list of .c files
c_files=(*.c(N))

# Check if any C files were found
if [ ${#c_files[@]} -eq 0 ]; then
    echo -e "${RED}No C files found in current directory.${NC}"
    exit 1
fi

# Use fzf to select files
echo -e "${CYAN}Select C files to compile (use Tab to select multiple files):${NC}"
selected_files=($(printf '%s\n' "${c_files[@]}" | fzf --multi))

# Ensure user selected at least one file
if [ ${#selected_files[@]} -eq 0 ]; then
    echo -e "${RED}No files selected.${NC}"
    exit 1
fi

# Extract base names without .c extension
selected_base_names=("${selected_files[@]%.*}")

# If multiple files selected, prompt for output name
if [ ${#selected_files[@]} -gt 1 ]; then
    echo -en "${WHITE}\nMultiple files selected. Please enter output filename (without extension):\n-> ${NC}"
    read output_name
    # Ensure output name is provided
    if [ -z "$output_name" ]; then
        echo -e "${RED}No output name provided. Please specify an output filename.${NC}"
        exit 1
    fi
else
    # Single file selected, use file name without extension
    output_name="${selected_base_names[@]}"
fi

# Check if the output file already exists
if [ -f "$output_name.out" ]; then
    echo -en "${YELLOW}Output file already exists. Overwrite? [Y/n] -> ${NC}"
    read overwrite_choice
    if [[ "$overwrite_choice" == "n" || "$overwrite_choice" == "N" ]]; then
        echo -e "${RED}Operation cancelled.${NC}"
        exit 1
    fi
fi

# Ask if the user wants to compile with debug info
echo -en "${YELLOW}Compile with debug information? [y/N] -> ${NC}"
read debug_choice

# Default to 'N' (no debug) if the user presses Enter without input
if [[ "$debug_choice" == "y" || "$debug_choice" == "Y" ]]; then
    echo -e "${BLUE}Compiling ${selected_files[@]} with debug symbols...${NC}\n"
    gcc "${selected_files[@]}" -Wall -g -Og -o "$output_name.out"

    # Check if compilation succeeded
    if [ $? -ne 0 ]; then
        echo -e "${RED}Compilation failed. Check your code for errors.${NC}"
        exit 1
    fi

    # Show LLDB TL;DR
    show_lldb_tldr

else
    echo -e "${BLUE}Compiling ${selected_files[@]} without debug symbols...${NC}\n"
    gcc "${selected_files[@]}" -Wall -O2 -o "$output_name.out"

    # Check if compilation succeeded
    if [ $? -ne 0 ]; then
        echo -e "${RED}Compilation failed. Check your code for errors.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Compilation complete. Executable is ./$output_name.out${NC}"

# Ask if the user wants to run the program now
echo -en "${WHITE}Do you want to run the program now? [Y/n] -> ${NC}"
read run_choice

if [[ "$run_choice" != "n" && "$run_choice" != "N" ]]; then
    # Ask for program arguments
    echo -en "${WHITE}Enter any arguments for the program (leave blank for none): ${NC}"
    read program_args
    echo -e "${CYAN}Running ./$output_name.out $program_args${NC}\n"
    "./$output_name.out" $program_args
fi

# Re-enable the 'nomatch' option
setopt nomatch
