#!/bin/zsh

# This script, JavaCompiler, serves as a versatile command-line utility for Java developers, facilitating the compilation and execution of Java files. It's designed to seamlessly interact with different Java project structures, specifically tailored for IntelliJ IDEA projects and Generic Java projects. Users benefit from an interactive menu that allows them to choose the project context or rerun previously executed files efficiently. The script ensures a clean working environment by managing temporary .class files, thus preventing clutter. Additionally, it offers robust error handling and presents compilation and execution errors in an easily understandable format. This utility is especially useful for developers looking for a quick and streamlined way to compile and test their Java code outside of an IDE.

# COLOR CODES
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

# ----------------------------- #

# Check for required dependencies
for cmd in fzf bat javac java; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}Error: '$cmd' is not installed. Please install '$cmd' to use this script.${NC}"
        exit 1
    fi
done

# ----------------------------- #

version="1.0"
help_message="${BLUE}Usage: $(basename "$0") [OPTIONS]
${NC}- ${ORANGE}IntelliJ IDEA Project:${NC} Run the script from the root directory of the IntelliJ IDEA project. 
  The script will navigate to the 'src' directory, where you can choose which Java source file 
  to compile and run.
${NC}- ${ORANGE}Generic Java Project:${NC} Run the script from a directory containing Java files. You will be 
  presented with a list of all Java files found within the directory. Select the Java file 
  you wish to compile and run.
${NC}- ${ORANGE}Argument Handling:${NC} The script allows you to provide arguments for the Java file you want to run.
  Enter the arguments separated by spaces when prompted.

${BLUE}A versatile command-line utility for Java developers to compile and run Java files.
${NC}OPTIONS:
${GREEN}-h, --help      ${NC}Display this help message and exit.
${GREEN}-v, --version   ${NC}Display version information and exit."

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) echo -e "$help_message"; exit 0 ;;
        -v|--version) echo -e "${GREEN}$version${NC}"; exit 0 ;;
        *)
            # Display the unknown option error followed by the options list
            echo -e "${RED}Unknown option: $1${NC}\n${NC}\nOptions:\n${GREEN}-h, --help      ${NC}Display help message and exit.\n${GREEN}-v, --version   ${NC}Display version information and exit." >&2
            exit 1
            ;;
    esac
    shift
done

# ----------------------------- #

# Get the directory where the script is located
script_dir="$(cd "$(dirname "$0")" && pwd)"
# Path for storing the last run file relative to the script's location
last_run_file="${script_dir}/last_run.txt"

# Global variable to hold the directory of the currently processed Java file
current_java_file_dir=""

# Improved Cleanup Function
cleanup() {
    echo -e "\n${RED}Execution interrupted. Cleaning up...${NC}"
    if [[ -n "$current_java_file_dir" && -d "$current_java_file_dir" ]]; then
        # Use a nullglob option to handle the case where no .class files are found
        setopt local_options nullglob
        class_files=("${current_java_file_dir}"/*.class)

        if [[ ${#class_files[@]} -eq 0 ]]; then
            echo -e "${GREEN}No .class files found in $current_java_file_dir. No cleanup needed.${NC}"
        else
            for class_file in "${class_files[@]}"; do
                if rm -f "$class_file"; then
                    # Extracting just the directory and file name, excluding the full path
                    dir_name=$(dirname "$class_file")
                    base_name=$(basename "$class_file")
                    short_path="${dir_name##*/}/$base_name"
                    echo -e "${GREEN}Deleted ${short_path}${NC}"
                else
                    # Similar extraction for the failed deletion case
                    dir_name=$(dirname "$class_file")
                    base_name=$(basename "$class_file")
                    short_path="${dir_name##*/}/$base_name"
                    echo -e "${RED}Failed to delete ${short_path}${NC}"
                fi
            done
            echo -e "${GREEN}Cleanup completed.${NC}"
        fi

        # Update the flag to prevent repeated cleanup operations
        cleanup_executed=true
    else
        echo -e "${RED}No valid directory set for cleanup or directory does not exist.${NC}"
    fi
    exit
}

compile_and_run() {
    # Set the trap with a check to ensure cleanup runs only once
    trap 'cleanup' SIGINT

    java_file_path=$1

    # Update the last run file and current directory for cleanup
    # Ensure last_run_file exists
    if [ ! -f "$last_run_file" ]; then
        touch "$last_run_file" || { echo -e "${RED}Failed to create $last_run_file.${NC}"; exit 1; }
    fi
    echo "$java_file_path" > "$last_run_file" || { echo -e "${RED}Failed to write to $last_run_file.${NC}"; return 1; }

    current_java_file_dir=$(pwd)/$(dirname "$java_file_path")

    # Compilation logic
    echo ""
    echo -e "${GREEN}Selected Java File:${NC} $java_file_path"
    compile_command=("javac" "$java_file_path")
    echo -e "${BLUE}Compiling Java file:${NC} ${compile_command[*]}"

    if ! "${compile_command[@]}" 2> compile_errors.txt; then
        echo -e "${RED}Compilation failed.${NC}\n"
        if command -v bat >/dev/null 2>&1; then
            echo -e "${RED}Compilation errors:${NC}"
            bat --language=java --style=plain compile_errors.txt
        else
            echo -e "${RED}Compilation errors:${NC}"
            cat compile_errors.txt
        fi
        rm compile_errors.txt

        # Clear the trap to prevent cleanup if returning early due to failure
        trap - SIGINT

        return 1
    else
        rm compile_errors.txt
    fi

    # Execution logic
    class_name=$(basename "$java_file_path" .java)
    echo -e "${GREEN}Compiled class:${NC} $class_name.class"

    echo -e "${BLUE}Enter arguments (separated by space):${NC}"
    read input_args

    # Convert input string to an array only if it's not empty
    if [ -n "$input_args" ]; then
        read -A args <<< "$input_args"
    else
        args=()
    fi

    java_file_path_without_extension=${java_file_path%.java}

    if [ ${#args[@]} -eq 0 ]; then
        run_command=("java" "${java_file_path_without_extension//\//.}")
    else
        run_command=("java" "${java_file_path_without_extension//\//.}" "${args[@]}")
    fi

    echo -e "${BLUE}Running Java file:${NC} ${run_command[*]}"
    echo "-----------------------------------------------------\n"

    if ! "${run_command[@]}"; then
        echo -e "${RED}Execution failed.${NC}"
        cleanup
        trap - SIGINT
        return 1
    fi

    # Delete all .class files in the directory of the .java file after successful execution
    class_file_dir=$(dirname "$java_file_path")
    rm ${class_file_dir}/*.class

    # Cleanup logic is only triggered upon receiving SIGINT (Ctrl+C)
    # If the script reaches this point without interruption, clear the trap
    trap - SIGINT
}

jcr() {
    current_dir=$(pwd)
    while true; do
        echo ""
        echo -e "${BLUE}Select project structure or action:${NC}"
        echo "1) IntelliJ IDEA Project"
        echo "2) Generic Java Project"
        if [ -f "$last_run_file" ]; then
            java_file_path=$(cat "$last_run_file")
            echo "3) Re-run Last Executed File (${ORANGE}${java_file_path}${NC})"
        fi
        echo "0) Exit Script"
        echo -n "> "
        read -r project_structure

        case $project_structure in
            1)
                handle_intellij_project "$current_dir"
                break
                ;;

            2)
                handle_java_project "$current_dir"
                break
                ;;

            3)
                if [ -f "$last_run_file" ]; then
                    java_file_path=$(cat "$last_run_file")
                    cd src || return # Change to src directory
                    compile_and_run "$java_file_path"
                    cd "$current_dir" || return
                    break
                else
                    echo -e "${RED}No last file to run. Please select a project structure.${NC}"
                fi
                ;;

            0) # Exit the script
                echo -e "${GREEN}Exiting.${NC}"
                exit
                ;;

            *) echo -e "${RED}Invalid selection. Please try again.${NC}"
                ;;
        esac
    done
}

handle_intellij_project() {
    current_dir=$1
    # Check if the 'src' directory exists
    if [ ! -d "src" ]; then
        echo -e "${RED}Error: 'src' directory not found in the current location.${NC}"
        echo -e "${RED}Please run the script from the root of your IntelliJ IDEA project.${NC}"
        return 1
    fi

    # IntelliJ IDEA project structure
    cd src || return

    # Find the relative path of the java file from the 'src' directory
    java_file_path=$(find . -name "*.java" | fzf --preview 'bat --color=always --style=header-filename {}' --preview-window right:60% --prompt="Select Java File: ")

    if [ -n "$java_file_path" ]; then
        java_file_path="${java_file_path#./}"
        compile_and_run "$java_file_path"
        cd "$current_dir" || return
    else
        echo -e "${RED}No Java file selected. Exiting.${NC}"
    fi
}

handle_java_project() {
    current_dir=$1
    java_file_path=$(find . -name "*.java" | fzf --preview 'bat --color=always --style=header-filename {}' --preview-window right:60% --prompt="Select Java File: ")

    if [ -n "$java_file_path" ]; then
        java_file_path="${java_file_path#./}"
        compile_and_run "$java_file_path"
    else
        echo -e "${RED}No Java file selected. Exiting.${NC}"
    fi
}

# Main function to wrap the script's logic
main() {
    jcr
}

# Call the main function to start the script
main "$@"
