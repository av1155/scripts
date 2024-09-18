#!/bin/zsh

# This script, JavaProjectManager, serves as a versatile command-line utility for Java developers, facilitating the compilation and execution of Java files. It's designed to seamlessly interact with different Java project structures, specifically tailored for IntelliJ IDEA projects and Generic Java files. Users benefit from an interactive menu that allows them to choose the project context or rerun previously executed files efficiently. The script ensures a clean working environment by managing temporary .class files, thus preventing clutter. Additionally, it offers robust error handling and presents compilation and execution errors in an easily understandable format. This utility is especially useful for developers looking for a quick and streamlined way to compile and test their Java code outside of an IDE.

# COLOR CODES
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

# ----------------------------- #

# Check for required dependencies
for cmd in fzf bat javac java; do
	if ! command -v $cmd &>/dev/null; then
		echo -e "${RED}Error: '$cmd' is not installed. Please install '$cmd' to use this script.${NC}"
		exit 1
	fi
done

# ----------------------------- #

version="2.1.0"
help_message="${BLUE}Usage: $(basename "$0") [OPTIONS]
${NC}- ${ORANGE}IntelliJ IDEA Project:${NC} Run the script from the root directory of the IntelliJ IDEA project. 
  The script will navigate to the 'src' directory, where you can choose which Java source file 
  to compile and run.
${NC}- ${ORANGE}Maven Project:${NC} Run the script from the root directory of the Maven project.
  The script will navigate to the 'src/main/java' directory, where you can choose which Java source file
  to compile and run. Ensure the 'pom.xml' file is present in the directory.
${NC}- ${ORANGE}Maven Test:${NC} Run the script from the root directory of the Maven project.
  The script will run the 'mvn test' command to execute the tests.
${NC}- ${ORANGE}Generic Java File:${NC} Run the script from a directory containing Java files. You will be 
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
	-h | --help)
		echo -e "$help_message"
		exit 0
		;;
	-v | --version)
		echo -e "${GREEN}$version${NC}"
		exit 0
		;;
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

cleanup() {
	echo -e "\n${RED}Execution interrupted. Cleaning up...${NC}"

	if [ -f "$last_run_file" ]; then
		if ! read last_java_file_info <"$last_run_file"; then
			echo -e "${RED}Failed to read the last run file.${NC}"
			return 1
		fi
		project_type=$(echo "$last_java_file_info" | cut -d':' -f2)

		case $project_type in
		"Maven")
			base_dir="${current_dir}/src/main/java"
			;;
		"IntelliJ")
			base_dir="${current_dir}/src"
			;;
		"Generic")
			base_dir="$current_dir"
			;;
		*)
			echo -e "${RED}Unrecognized project type for cleanup.${NC}"
			base_dir="$current_dir"
			;;
		esac
	else
		echo -e "${RED}No last run file found for cleanup.${NC}"
		return 1
	fi

	echo -e "${ORANGE}Starting cleanup of .class files from: ${base_dir}${NC}"

	if ! find "$base_dir" -type f -name '*.class' -exec bash -c 'BLUE="\033[0;34m"; NC="\033[0m"; echo -e "${BLUE}Deleting $(echo "$2" | sed "s|$1||")${NC}"' _ "$base_dir" '{}' \; -delete; then
		echo -e "${RED}Cleanup failed.${NC}"
		return 1
	fi

	echo -e "${GREEN}Cleanup completed; all .class files removed from ${base_dir}.${NC}"
	exit 0
}

compile_and_run() {
	# Set the trap with a check to ensure cleanup runs only once
	trap 'cleanup' SIGINT

	java_file_path=$1 # The path of the Java file to compile and run
	project_type=$2   # The type of project structure (IntelliJ, Maven, or Generic)

	# Update the last run file and current directory for cleanup
	if [ ! -f "$last_run_file" ]; then
		touch "$last_run_file" || {
			echo -e "${RED}Failed to create $last_run_file.${NC}"
			exit 1
		}
	fi
	echo "${java_file_path}:${project_type}" >"$last_run_file" || {
		echo -e "${RED}Failed to write to $last_run_file.${NC}"
		return 1
	}

	# Store the directory of the Java file for cleanup
	current_java_file_dir=$(pwd)/$(dirname "$java_file_path")

	# Compilation logic
	echo ""
	echo -e "${GREEN}Selected Java File:${NC} $java_file_path"
	compile_command=("javac" "$java_file_path")
	echo -e "${BLUE}Compiling Java file:${NC} ${compile_command[*]}"

	if ! "${compile_command[@]}" 2>compile_errors.txt; then
		echo -e "${RED}Compilation failed.${NC}\n"
		if command -v bat >/dev/null 2>&1; then
			echo -e "${RED}Compilation errors:${NC}"
			bat --language=bash --style=plain compile_errors.txt
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

	# Ask for JVM options
	echo -e "${BLUE}Enter JVM options (e.g., -Xmx10g) or press Enter to skip:${NC}"
	read jvm_options

	# Execution logic
	class_name=$(basename "$java_file_path" .java)
	echo -e "${GREEN}Compiled class:${NC} $class_name.class"

	echo -e "${BLUE}Enter arguments (separated by space):${NC}"
	read input_args

	# Convert input string to an array only if it's not empty
	if [ -n "$input_args" ]; then
		read -A args <<<"$input_args"
	else
		args=()
	fi

	java_file_path_without_extension=${java_file_path%.java}

	# Build the run command with JVM options if provided
	if [ -n "$jvm_options" ]; then
		run_command=("java" $jvm_options "${java_file_path_without_extension//\//.}")
	else
		run_command=("java" "${java_file_path_without_extension//\//.}")
	fi

	# Append any program arguments to the run command
	if [ ${#args[@]} -ne 0 ]; then
		run_command+=("${args[@]}")
	fi

	echo -e "${BLUE}Running Java file:${NC} ${run_command[*]}"
	echo "-----------------------------------------------------\n"

	if ! "${run_command[@]}"; then
		echo -e "${RED}Execution failed.${NC}"
		cleanup >/dev/null 2>&1
		trap - SIGINT
		return 1
	fi

	# Delete all .class files in the directory of the project after successful execution
	cleanup >/dev/null 2>&1

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
		echo "2) IntelliJ Maven Project"
		echo "3) Generic Java File"
		if [ -f "$last_run_file" ]; then
			last_java_file_path=$(cat "$last_run_file")
			echo "4) Re-run Last Executed File (${ORANGE}${last_java_file_path}${NC})"
		fi
		echo "5) Maven Test"
		echo "0) Exit Script"
		echo -n "> "
		read -r project_structure

		case $project_structure in
		1)
			handle_intellij_project "$current_dir"
			break
			;;

		2)
			handle_intellij_maven_project "$current_dir"
			break
			;;

		3)
			handle_java_file "$current_dir"
			break
			;;

		4)
			if [ -f "$last_run_file" ]; then
				read last_java_file_info <"$last_run_file"
				last_java_file_path=$(echo $last_java_file_info | cut -d':' -f1) # Extract file path
				project_type=$(echo $last_java_file_info | cut -d':' -f2)        # Extract project type

				case $project_type in
				"Maven")
					java_file_dir="${current_dir}/src/main/java"
					;;
				"IntelliJ")
					java_file_dir="${current_dir}/src"
					;;
				"Generic")
					java_file_dir="$current_dir"
					;;
				*)
					java_file_dir="$current_dir" # Default
					;;
				esac

				cd "$java_file_dir" || {
					echo -e "${RED}Failed to change directory to $java_file_dir. Exiting.${NC}"
					return
				}

				compile_and_run "$last_java_file_path" "$project_type"
				cd "$current_dir" || return
				break
			else
				echo -e "${RED}No last file to run. Please select a project structure.${NC}"
			fi
			;;

		5)
			if [ ! -f "pom.xml" ]; then
				echo -e "${RED}Error: 'pom.xml' not found in the current location.${NC}"
				echo -e "${RED}Please run the script from the root of your Maven project.${NC}"
				break
			fi
			echo -e "\n${BLUE}Running Maven Test...${NC}"
			if ! command -v mvn &>/dev/null; then
				echo -e "${RED}Error: 'mvn' is not installed. Please install Maven to use this feature.${NC}"
				break
			fi
			mvn test
			break
			;;

		0) # Exit the script
			echo -e "${GREEN}Exiting.${NC}"
			exit
			;;

		*)
			echo -e "${RED}Invalid selection. Please try again.${NC}"
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
		compile_and_run "$java_file_path" "IntelliJ"
		cd "$current_dir" || return
	else
		echo -e "${RED}No Java file selected. Exiting.${NC}"
	fi
}

handle_intellij_maven_project() {
	local current_dir=$1
	# Ensure the script is run from the root of the Maven project
	if [ ! -f "pom.xml" ]; then
		echo -e "${RED}Error: 'pom.xml' not found in the current location.${NC}"
		echo -e "${RED}Please run the script from the root of your IntelliJ Maven project.${NC}"
		return 1
	fi

	# Navigate to the source directory
	cd src/main/java || return

	# Find the relative path of the java file from the 'src/main/java' directory
	java_file_path=$(find . -name "*.java" | fzf --preview 'bat --color=always --style=header-filename {}' --preview-window right:60% --prompt="Select Java File: ")

	if [ -n "$java_file_path" ]; then
		java_file_path="${java_file_path#./}" # Remove leading './'
		compile_and_run "$java_file_path" "Maven"
		cd "$current_dir" || return # Return to the original directory
	else
		echo -e "${RED}No Java file selected. Exiting.${NC}"
	fi
}

handle_java_file() {
	current_dir=$1
	java_file_path=$(find . -name "*.java" | fzf --preview 'bat --color=always --style=header-filename {}' --preview-window right:60% --prompt="Select Java File: ")

	if [ -n "$java_file_path" ]; then
		java_file_path="${java_file_path#./}"
		compile_and_run "$java_file_path" "Generic"
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
