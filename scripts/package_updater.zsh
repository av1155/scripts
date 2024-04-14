#!/bin/zsh

# Package Updater
# A script to update Homebrew, Conda environments, Oh My Zsh, Mac App Store applications, Node.js, npm packages, and AstroNvim plugins.

# If the script is run non-interactively (e.g., cron job), set the PATH and ZSH variables
if [ ! -t 0 ]; then
	# Set the PATH to include Homebrew's bin directory and system paths
	export PATH="/opt/homebrew/bin:$PATH"

	# Set the ZSH variable to the Oh My Zsh directory
	export ZSH="/Users/andreaventi/.oh-my-zsh"
fi

# Initialize Conda for script usage
[ -s "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh" ] && source "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh"

# Initialize NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"


# VARIABLES & HELPER FUNCTIONS ====================================================

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
	command -v "$1" >/dev/null 2>&1
}

echo_color() {
    color_code="$1"
    shift
    echo -e "${color_code}$@${NC}"
}


# PACKAGE UPDATE FUNCTIONS ========================================================

# Update Homebrew
update_homebrew() {
    if command_exists brew; then
        echo_color $BLUE "Updating Homebrew..."
        brew update
        brew upgrade
        brew cleanup
        brew autoremove
        echo_color $ORANGE "====================================================================================\n"
    else
        echo_color $RED "Homebrew not found. Skipping..."
    fi
}


# Update miniforge + Conda environments
update_conda_environments() {
	if command_exists conda; then
    	echo_color $BLUE "Updating all Conda environments..."
    	echo_color $GREEN "\nActivating and updating base..."
		conda update --all -y
		conda clean --all -y

    	for env in $(conda env list | awk '{print $1}' | grep -vE '^\#|base'); do
        	echo_color $GREEN "\nActivating and updating $env..."
        	conda activate $env
        	conda update --all -y
        	conda clean --all -y
        	conda deactivate
    	done

    	echo_color $GREEN "All Conda environments have been updated."
        echo_color $ORANGE "====================================================================================\n"
	else
		echo_color $RED "miniforge not found. Skipping..."
	fi
}


# Update Oh My Zsh
update_omz() {
	if [ -d "$HOME/.oh-my-zsh" ]; then
		"$ZSH/tools/upgrade.sh"
		"$ZSH/tools/changelog.sh"
        echo_color $ORANGE "====================================================================================\n"
	else
		echo_color $RED "Oh My Zsh not found. Skipping..."
	fi
}


# Update Mac App Store applications
update_mas() {
    if command_exists mas; then
        echo_color $BLUE "Updating Mac App Store applications..."
        local outdated_apps=$(mas outdated)
        echo "$outdated_apps"

        # Define an array of app IDs to ignore
        local ignore_list=("1365531024" "appID2" "appID3")  # Add app IDs here

        # Loop through each outdated app and update if not in the ignore list
        echo "$outdated_apps" | while read -r line; do
            local app_id=$(echo $line | awk '{print $1}')
            local app_name=$(echo $line | cut -d ' ' -f 2-)

            # Check if the app ID is in the ignore list
            if [[ ! "${ignore_list[@]}" =~ "$app_id" ]]; then
                echo "Updating $app_name..."
                mas upgrade $app_id
            else
                echo_color $PURPLE "Skipping $app_name..."
            fi
        done
        echo_color $ORANGE "====================================================================================\n"
    else
        echo_color $RED "Mac App Store CLI not found. Skipping..."
    fi
}


# Update Node.js using NVM
update_node() {
	if command_exists nvm; then
		echo_color $BLUE "Updating Node.js..."

		# Get the current version of Node.js
		CURRENT_NODE_VERSION=$(nvm current | sed 's/\x1b\[[0-9;]*m//g')

		# Get the latest LTS Node.js version and strip ANSI escape codes
		LATEST_LTS_VERSION=$(nvm ls-remote --lts | tail -1 | awk '{ print $2 }' | sed 's/\x1b\[[0-9;]*m//g')

		# Debug: Print versions for checking
		echo "Current Node version:${PURPLE} ${CURRENT_NODE_VERSION} ${NC}"
		echo "Latest LTS version:${PURPLE} $(nvm ls-remote --lts | tail -1) ${NC}"

		if [ "$CURRENT_NODE_VERSION" != "$LATEST_LTS_VERSION" ]; then
    		# Install the latest LTS Node.js version and reinstall packages from the current version
    		nvm install --lts --reinstall-packages-from="$CURRENT_NODE_VERSION" || { echo_color $RED "Failed to update Node.js."; exit 1; }

    		# Switch to the latest Node.js version
    		nvm use --lts || { echo_color $RED "Failed to switch to the latest Node.js version."; exit 1; }

    		# Check the new current version after update
    		NEW_NODE_VERSION=$(nvm current | sed 's/\x1b\[[0-9;]*m//g')

    		# Uninstall the old version if it's different from the new version
    		if [ "$NEW_NODE_VERSION" != "$CURRENT_NODE_VERSION" ]; then
        		echo -e "${BLUE}Uninstalling the old version of Node.js${NC} ${PURPLE}${CURRENT_NODE_VERSION}${NC}..."
        		nvm uninstall "$CURRENT_NODE_VERSION" || { echo_color $RED "Failed to uninstall the old version of Node.js."; exit 1; }
    		fi

    		echo_color $GREEN "Node.js has been updated to the latest LTS version: ${NEW_NODE_VERSION}"

		else
			echo_color $BLUE "Already on the latest LTS version of Node.js."
		fi
        echo_color $ORANGE "====================================================================================\n"
	else
    	echo_color $RED "NVM not found. Skipping Node.js update..."
	fi
}


# Update npm packages
update_npm() {
	if command_exists npm; then
    	if [ -t 0 ]; then
        	# Interactive mode
        	echo_color $BLUE "Do you want to update npm? (y/n)"
        	# Set a 10-second timeout for user response
        	read -r -t 10 update_choice
        	if [[ $? -eq 0 ]] && [[ "$update_choice" == "y" || "$update_choice" == "Y" ]]; then
            	echo_color $BLUE "Updating npm..."
            	npm update -g || { echo_color $RED "Failed to update npm."; exit 1; }
        	else
            	echo_color $GREEN "Skipping npm update."
        	fi
    	else
        	# Non-interactive mode (e.g., cron job)
        	echo_color $BLUE "Updating npm in non-interactive mode..."
        	npm update -g || { echo_color $RED "Failed to update npm."; exit 1; }
    	fi
        echo_color $ORANGE "====================================================================================\n"
	else
		echo_color $RED "npm not found. Skipping..."
	fi
}


# Update AstroNvim
update_astronvim() {
	if command_exists nvim; then
    	local lazy_lock_file="$HOME/.config/nvim/lazy-lock.json"
    	local backup_file="/tmp/nvim-lazy-lock.json.backup"

    	# Backup the current config
    	cp "$lazy_lock_file" "$backup_file"

    	# Run update commands
    	echo_color $BLUE "Updating AstroNvim..."
    	nvim --headless "+AstroUpdate" +qa
    	nvim --headless "+AstroMasonUpdateAll" +qa
    	nvim --headless "+Lazy sync" +qa
    	nvim --headless "+TSUpdate" +qa

    	# Check for differences
    	echo_color $ORANGE "\nChecking for changes in lazy-lock.json..."
    	local changes=$(diff -u "$backup_file" "$lazy_lock_file" | grep '^\(+\|-\)' | grep -v '^+++' | grep -v '^---')
    	if [ -n "$changes" ]; then
        	echo_color $RED "Changes detected in lazy-lock.json:"
        	echo "$changes" | bat -l json
    	else
        	echo_color $GREEN "No changes detected in lazy-lock.json."
    	fi

        echo_color $ORANGE "====================================================================================\n"
	else
		echo_color $RED "Neovim not found. Skipping AstroNvim update..."
	fi
}


# MAIN SCRIPT =====================================================================

# Function to manage log files
manage_log_files() {
    local log_dir="/Users/andreaventi/scripts/logs"
    local max_logs=30  # Set the maximum number of log files to keep

    echo "Changing to directory: $log_dir"
    cd "$log_dir"  # Navigate to the log directory

    # List all log files sorted by modification time
    local log_files=($(ls -t upall_*.log 2>/dev/null))

    # Check the number of logs
    local number_of_logs=${#log_files[@]}
    echo_color $BLUE "Number of log files: $number_of_logs"

    if [ $number_of_logs -gt $max_logs ]; then
        # Calculate how many files to remove
        local files_to_remove_count=$((number_of_logs - max_logs))
        local files_to_remove=(${log_files[@]:$max_logs:$files_to_remove_count})

        echo_color $BLUE "Removing old log files: ${files_to_remove[@]}"
        rm "${files_to_remove[@]}"  # Remove the oldest log files
    else
        echo_color $BLUE "No log files need to be removed."
    fi

    cd -
}


# Send an email with the log file if the script is run non-interactively
send_update_report() {
    LOG_FILE="/Users/andreaventi/scripts/logs/upall_$(date +\%Y-\%m-\%d-05\%p).log"
    if [ -f "$LOG_FILE" ]; then
        {
            echo "To: andrea.venti12@gmail.com"
            echo "From: andrea.venti12@gmail.com"
            echo "Subject: Package Updater Output"
            echo ""
            cat "$LOG_FILE"
        } | msmtp -t
    else
        echo "Log file not found: $LOG_FILE" >&2
    fi
}


# Main script execution
main() {
    update_homebrew
    update_conda_environments
    update_omz
    update_mas
    update_node
    update_npm
    update_astronvim
    echo_color $GREEN "All applicable packages and applications updated."

    # Manage log files to keep only the most recent $max_logs
    manage_log_files

    # Post-update tasks
    if [ ! -t 0 ]; then
        send_update_report
    fi
}

main
