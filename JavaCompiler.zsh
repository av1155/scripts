# JCR EDGE VERSION (COLOR) -----------------------------------:

# Define some color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# END OF EDGE VERSION (COLOR) ------------------------------------------


# CHANGES: Compile and run without arguments -----------------------------

# compile_and_run() {
#   java_file_path=$1
#
#   # Output debug information
#   echo "Selected Java File: $java_file_path"
#
#   # Compile the Java file
#   compile_command=("javac" "$java_file_path")
#   echo "Compiling Java file: ${compile_command[*]}"
#   "${compile_command[@]}"
#
#   # Get the class name without the '.java' extension
#   class_name=$(basename "$java_file_path" .java)
#
#   # Output debug information
#   echo "Compiled class: $class_name.class"
#
#   # Generate the run command by modifying the java_file_path
#   java_file_path_without_extension=${java_file_path%.java}
#   run_command=("java" "${java_file_path_without_extension//\//.}")
#   echo "Running Java file: ${run_command[*]}"
#   echo ""
#   "${run_command[@]}"
#
#   # Delete the compiled class
#   class_file_path="${java_file_path_without_extension}.class"
#   rm "$class_file_path"
# }

# CHANGES END -------------------------------------------------------------




# Just IntelliJ IDEA project structure -----------------------------------:

# # Java Compile and Run Script (jcr)
# jcr() {
#   # Get the current directory
#   current_dir=$(pwd)
#
#   # Find the relative path of the java file from the 'src' directory
#   # java_file_path=$(find . -name "*.java" | fzf --prompt="Select Java File: ")
#   # Find the relative path of the java file from the 'src' directory
#   java_file_path=$(find . -name "*.java" | fzf --preview 'bat --color=always {}' --prompt="Select Java File: ")
#
#   # Check if a Java file was selected
#   if [ -n "$java_file_path" ]; then
#     # Remove the leading './' from the path
#     java_file_path="${java_file_path#./}"
#
#     # Output debug information
#     echo "Selected Java File: $java_file_path"
#
#     # Compile the Java file from within the 'src' directory
#     compile_command=("javac" "$java_file_path")
#     echo "Compiling Java file: ${compile_command[*]}"
#     "${compile_command[@]}"
#
#     # Get the class name without the '.java' extension
#     class_name=$(basename "$java_file_path" .java)
#
#     # Output debug information
#     echo "Compiled class: $class_name.class"
#
#     # Generate the run command by modifying the java_file_path
#     java_file_path_without_extension=${java_file_path%.java}
#     run_command=("java" "${java_file_path_without_extension//\//.}")
#     echo "Running Java file: ${run_command[*]}"
#     echo ""
#     "${run_command[@]}"
#
#     # Delete the compiled class from within the 'src' directory
#     class_file_path="${java_file_path_without_extension}.class"
#     rm "$class_file_path"
#
#     # Return to the original directory
#     cd "$current_dir" || return
#   else
#     echo "No Java file selected. Exiting."
#   fi
# }

# # END OF JUST INTELLIJ IDEA PROJECT STRUCTURE ---------------------------
