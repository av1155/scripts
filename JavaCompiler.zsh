# START OF SCRIPT ---------------------------------------------------

# JavaCompiler is a script that allows users to compile and run Java files from the command line. The script also includes functions to handle various project structures, such as IntelliJ IDEA and JavaProjects, allowing for easy integration into these development environments. Additionally, the script provides error handling and debugging information for both compilation and execution of Java programs.

# Define some color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


# Cleanup function to remove *.class files
cleanup_class_files() {
    echo -e "${RED}Interrupted. Cleaning up .class files...${NC}"
    find . -name "*.class" -exec rm {} +
}

# Trap SIGINT (Ctrl+C) to execute the cleanup_class_files function
trap cleanup_class_files SIGINT


compile_and_run() {
    java_file_path=$1

    # Output debug information
    echo -e "${GREEN}Selected Java File:${NC} $java_file_path"

    # Compile the Java file
    compile_command=("javac" "$java_file_path")
    echo -e "${BLUE}Compiling Java file:${NC} ${compile_command[*]}"
    if ! "${compile_command[@]}" 2> compile_errors.txt; then
        echo -e "${RED}Compilation failed.${NC}"
        echo -e "${RED}Detailed errors:${NC}"
        bat --color=always compile_errors.txt
        rm compile_errors.txt
        return 1
    else
        # Remove the error file if compilation was successful
        rm compile_errors.txt
    fi

    # Get the class name without the '.java' extension
    class_name=$(basename "$java_file_path" .java)

    # Output debug information
    echo -e "${GREEN}Compiled class:${NC} $class_name.class"

    # Ask the user for arguments
    echo -e "${BLUE}Enter arguments (separated by space):${NC}"
    read -A args

    # Generate the run command by modifying the java_file_path
    java_file_path_without_extension=${java_file_path%.java}
    run_command=("java" "${java_file_path_without_extension//\//.}" "${args[@]}")
    echo -e "${BLUE}Running Java file:${NC} ${run_command[*]}"
    echo ""
    if ! "${run_command[@]}"; then
        echo -e "${RED}Execution failed.${NC}"
        return 1
    fi

    # Delete all .class files in the directory of the .java file
    class_file_dir=$(dirname "$java_file_path")
    rm ${class_file_dir}/*.class
}


jcr() {
    echo -e "${BLUE}Select project structure:${NC}"
    echo "1) IntelliJ IDEA"
    echo "2) JavaProject"
    echo -n "> "
    read -r project_structure

    # Get the current directory
    current_dir=$(pwd)

    if [ "$project_structure" = "1" ]; then
        handle_intellij_project "$current_dir"
    elif [ "$project_structure" = "2" ]; then
        handle_java_project "$current_dir"
    else
        echo -e "${RED}Invalid selection. Exiting.${NC}"
    fi
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
    java_file_path=$(find . -name "*.java" | fzf --preview 'bat --color=always {}' --prompt="Select Java File: ")

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
    java_file_path=$(find . -name "*.java" | fzf --preview 'bat --color=always {}' --prompt="Select Java File: ")

    if [ -n "$java_file_path" ]; then
        java_file_path="${java_file_path#./}"
        compile_and_run "$java_file_path"
    else
        echo -e "${RED}No Java file selected. Exiting.${NC}"
    fi
}


# END OF SCRIPT ----------------------------------------------------
