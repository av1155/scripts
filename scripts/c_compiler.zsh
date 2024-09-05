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

# Display available C files in the current directory
echo -e "${CYAN}Available C files in the current directory:${NC}"

# Check if colorls is installed, else use normal ls
if command -v colorls &>/dev/null; then
    colorls *.c 2>/dev/null
else
    ls *.c 2>/dev/null
fi

# Check if any C files were found
if [ $? -ne 0 ]; then
    echo -e "${RED}No C files found in current directory.${NC}"
else
    echo -e "${YELLOW}====================================================================${NC}"

    # Use echo -n to print the prompt without a newline and then read the input
    echo -n -e "${WHITE}\nName + extension of C program in current working directory:\n-> ${NC}"
    read c_program

    # Check if the file exists
    if [ -f "$c_program" ]; then
        # Remove the .c extension to get the base name
        c_program_without_extension="${c_program%.c}"

        # Ask if the user wants to compile with debug info
        echo -n -e "${YELLOW}Compile with debug information? [y/N] -> ${NC}"
        read debug_choice

        # Default to 'N' (no debug) if the user presses Enter without input
        if [[ "$debug_choice" == "y" || "$debug_choice" == "Y" ]]; then
            echo -e "${BLUE}Compiling $c_program with debug symbols...${NC}\n"
            gcc "$c_program" -Wall -g -Og -o "$c_program_without_extension.out"

            # Display TL;DR on debugging with lldb
            echo -e "${CYAN}Run 'lldb ./$c_program_without_extension.out' to start debugging\n${NC}"
            echo -e "${CYAN}====================================================================${NC}"
            echo -e "${YELLOW}TL;DR: Basic LLDB Debugging Commands${NC}"
            echo -e "${CYAN}====================================================================${NC}"
            echo -e "${WHITE}(lldb) breakpoint set --name main  ${NC}# Set a breakpoint at the main function"
            echo -e "${WHITE}(lldb) run                         ${NC}# Run the program"
            echo -e "${WHITE}(lldb) next                        ${NC}# Step to the next line of code"
            echo -e "${WHITE}(lldb) print var                   ${NC}# Print the value of the variable 'var'"
            echo -e "${WHITE}(lldb) exit                        ${NC}# Exit"
            echo -e "${CYAN}====================================================================${NC}"

        else
            echo -e "${BLUE}Compiling $c_program without debug symbols...${NC}\n"
            gcc "$c_program" -Wall -O2 -o "$c_program_without_extension.out"
        fi

        # Check if compilation succeeded
        if [ $? -ne 0 ]; then
            echo -e "${RED}\nCompilation failed.${NC}"
        else
            echo -e "${GREEN}Compilation complete. Executable is ./$c_program_without_extension.out${NC}"
        fi

    else
        echo -e "${RED}File not found.${NC}"
    fi
fi

# Re-enable the 'nomatch' option
setopt nomatch
