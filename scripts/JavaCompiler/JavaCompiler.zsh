#!/bin/zsh

# START OF SCRIPT ---------------------------------------------------

# JavaCompiler is a script that allows users to compile and run Java files from the command line. The script also includes functions to handle various project structures, such as IntelliJ IDEA and JavaProjects, allowing for easy integration into these development environments. Additionally, the script provides error handling and debugging information for both compilation and execution of Java programs.

# Define some color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Path for storing the last run file
last_run_file="$HOME/scripts/scripts/JavaCompiler/last_run.txt"

# Global variable to hold the directory of the currently processed Java file
current_java_file_dir=""

# Improved Cleanup Function
cleanup() {
    echo -e "\n${RED}Execution interrupted. Cleaning up...${NC}"
    if [[ -n "$current_java_file_dir" && -d "$current_java_file_dir" ]]; then
        # Use a nullglob option to handle the case where no .class files are found
        setopt local_options nullglob
        class_files=("${current_java_file_dir}"/*.class)

        # Check if class_files array is not empty
        if [[ ${#class_files[@]} -gt 0 ]]; then
            rm -f "${class_files[@]}"
            echo -e "${GREEN}The .class files in $current_java_file_dir were removed successfully.${NC}"
        else
            echo -e "${GREEN}No .class files found in $current_java_file_dir. No cleanup needed.${NC}"
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
    echo "$java_file_path" > "$last_run_file"
    current_java_file_dir=$(pwd)/$(dirname "$java_file_path")

    # Compilation logic
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
    read -A args
    java_file_path_without_extension=${java_file_path%.java}
    run_command=("java" "${java_file_path_without_extension//\//.}" "${args[@]}")
    echo -e "${BLUE}Running Java file:${NC} ${run_command[*]}\n"
    if ! "${run_command[@]}"; then
        echo -e "${RED}Execution failed.${NC}"
        # Clear the trap to prevent cleanup if execution fails
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

    echo -e "${BLUE}Select project structure or action:${NC}"
    echo "1) IntelliJ IDEA"
    echo "2) JavaProject"
    if [ -f "$last_run_file" ]; then
        echo "3) Run Last File"
    fi
    echo -n "> "
    read -r project_structure

    case $project_structure in
        1)
            handle_intellij_project "$current_dir"
            ;;
        2)
            handle_java_project "$current_dir"
            ;;
        3)
            if [ -f "$last_run_file" ]; then
                java_file_path=$(cat "$last_run_file")
                cd src || return # Change to src directory
                compile_and_run "$java_file_path"
                cd "$current_dir" || return
            else
                echo -e "${RED}No last file to run. Please select a project structure.${NC}"
            fi
            ;;
        *)
            echo -e "${RED}Invalid selection. Exiting.${NC}"
            ;;
    esac
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

# END OF SCRIPT ----------------------------------------------------
