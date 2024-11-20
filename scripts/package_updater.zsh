#!/bin/zsh

# Package Updater
# A script to update Homebrew, Conda environments, Oh My Zsh, Mac App Store applications, Node.js, npm packages, and AstroNvim plugins.

# If the script is run non-interactively (e.g., cron job), set the PATH and ZSH variables
if [ ! -t 0 ]; then
	# Set the PATH to include Homebrew's bin directory and system paths
	export PATH="/opt/homebrew/bin:$PATH"

	# Set the ZSH variable to the Oh My Zsh directory
	export ZSH="/Users/andreaventi/.oh-my-zsh"

    # Ensure Homebrew Ruby is prioritized over system Ruby
    export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
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
		cd "$HOME/.dotfiles/App-Configs/configs/MacOS-Bootstrap"
		rm Brewfile
		brew bundle dump --describe --no-lock

		# Push changes to GitHub
		echo_color $BLUE "Pushing changes to GitHub..."
		git add .
		git commit -m "Updated Brewfile on $(date +'%Y-%m-%d %H:%M:%S')"
		if [ $? -eq 0 ]; then
			git push || {
				echo_color $RED "Failed to push changes to GitHub."
				exit 1
			}
		else
			echo_color $GREEN "No changes to commit."
		fi
		cd - >/dev/null

		echo_color $ORANGE "====================================================================================\n"
	else
		echo_color $RED "Homebrew not found. Skipping..."
	fi
}

# Function to remove YAML files for deleted Conda environments
remove_deleted_env_backups() {
    local BACKUP_DIR="${HOME}/CondaBackup"
    
    # Get a list of current Conda environments
    local current_envs=$(conda env list | awk '{print $1}' | grep -vE '^\#')

    echo_color $BLUE "Checking for deleted environments to remove from backup..."
    for file in "$BACKUP_DIR"/*.yml; do
        env_name=$(basename "$file" .yml)
        if ! echo "$current_envs" | grep -qx "$env_name"; then
            echo_color $ORANGE "Removing outdated environment backup: $env_name"
            rm "$file" || {
                echo_color $RED "Failed to delete outdated file $file."
                exit 1
            }
        fi
    done
    echo_color $GREEN "Cleanup of deleted environment backups complete."
    echo_color $ORANGE "====================================================================================\n"
}

# Update miniforge + Conda environments
update_conda_environments() {
	if command_exists conda; then
		echo_color $BLUE "Updating all Conda environments..."

		for env in $(conda env list | awk '{print $1}' | grep -vE '^\#'); do
			echo_color $GREEN "\nActivating and updating $env..."
			conda activate $env
			conda update --all -y
			conda clean --all -y
			conda deactivate
		done

		conda activate base

		echo_color $GREEN "\nAll Conda environments have been updated."
		echo_color $ORANGE "====================================================================================\n"
	else
		echo_color $RED "miniforge not found. Skipping..."
	fi
}

# Backup Conda environments
backup_conda_environments() {
	BACKUP_DIR="${HOME}/CondaBackup"

	# Check if git and conda are installed
	if ! command -v git &>/dev/null; then
		echo_color $RED "git is not installed. Please install git first."
		exit 1
	fi

	if ! command -v conda &>/dev/null; then
		echo_color $RED "conda is not installed. Please install conda first."
		exit 1
	fi

	# Check if the backup directory exists
	if [ ! -d "$BACKUP_DIR" ]; then
		echo_color $BLUE "CondaBackup directory not found. Cloning from GitHub..."
		git clone https://github.com/av1155/CondaBackup.git "$BACKUP_DIR" || {
			echo_color $RED "Failed to clone CondaBackup repository."
			exit 1
		}
	fi

	echo_color $BLUE "Backing up all Conda environments to $BACKUP_DIR..."

	for env in $(conda env list | awk '{print $1}' | grep -vE '^\#'); do
		echo_color $GREEN "\nBacking up environment $env..."
		conda env export --name "$env" >"$BACKUP_DIR/${env}.yml" || {
			echo_color $RED "Failed to back up environment $env."
			exit 1
		}
	done

	echo_color $GREEN "\nAll Conda environments have been backed up to $BACKUP_DIR."

	# Push changes to GitHub
	echo_color $BLUE "Pushing changes to GitHub..."
	cd "$BACKUP_DIR" || {
		echo_color $RED "Failed to change to the backup directory."
		exit 1
	}

	git add .
	git commit -m "Backup Conda environments on $(date +'%Y-%m-%d %H:%M:%S')"
	if [ $? -eq 0 ]; then
		git push || {
			echo_color $RED "Failed to push changes to GitHub."
			exit 1
		}
	else
		echo_color $GREEN "No changes to commit."
	fi
	cd - >/dev/null

	echo_color $ORANGE "====================================================================================\n"
}

# Function to update tmux TPM plugins
update_tmux_plugins() {
    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        echo_color $BLUE "Updating tmux TPM plugins..."
        "$HOME/.tmux/plugins/tpm/bin/update_plugins" all
        if [ $? -eq 0 ]; then
            echo_color $GREEN "\nAll tmux TPM plugins have been updated."
        else
            echo_color $RED "\nFailed to update tmux TPM plugins."
        fi
        echo_color $ORANGE "====================================================================================\n"
    else
        echo_color $RED "tmux TPM not found. Skipping..."
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
		echo_color $ORANGE "$outdated_apps"

		# Define an array of app IDs to ignore
		local ignore_list=("1365531024" "1444383602" "appID3" "etc") # Add app IDs here - Find with `mas list`

		# Loop through each outdated app and update if not in the ignore list
		echo "$outdated_apps" | while read -r line; do
			local app_id=$(echo $line | awk '{print $1}')
			local app_name=$(echo $line | cut -d ' ' -f 2-)

			# Check if the app ID is in the ignore list
			if [[ ! "${ignore_list[@]}" =~ "$app_id" ]]; then
				# Quit the app using AppleScript before updating
				echo_color $BLUE "Quitting $app_name..."
				osascript -e "tell application \"$app_name\" to quit"
				if [ "$?" -ne 0 ]; then
					echo_color $RED "Failed to quit $app_name."
				fi

				# Wait a little for the application to quit properly
				sleep 3

				echo_color $GREEN "Updating $app_name..."
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

# Function to update NVM (Node Version Manager)
update_nvm() {
    # Check if NVM is installed
    if [ -d "$HOME/.nvm" ]; then
        # Load NVM for version check
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        # Fetch the latest NVM version from GitHub README
        LATEST_NVM_VERSION=$(curl -sL 'https://raw.githubusercontent.com/nvm-sh/nvm/refs/heads/master/README.md' \
                                | grep -oE 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v[0-9]+\.[0-9]+\.[0-9]+/install.sh' \
                                | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' \
                                | head -n 1)

        # Default to v0.40.1 if no version is found
        if [ -z "$LATEST_NVM_VERSION" ]; then
            echo_color $RED "Failed to fetch the latest NVM version, defaulting to v0.40.1."
            LATEST_NVM_VERSION="v0.40.1"
        fi

        # Get the current installed NVM version
        CURRENT_NVM_VERSION=$(nvm --version 2>/dev/null)

        # Compare versions and update if needed
        if [ "$CURRENT_NVM_VERSION" != "${LATEST_NVM_VERSION#v}" ]; then
            echo_color $BLUE "Updating NVM from version $CURRENT_NVM_VERSION to $LATEST_NVM_VERSION..."
            curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${LATEST_NVM_VERSION}/install.sh" | bash || {
                echo_color $RED "Failed to update NVM."
                exit 1
            }
            # Reload NVM after update
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            echo_color $GREEN "NVM updated to version $LATEST_NVM_VERSION."
        else
            echo_color $GREEN "NVM is already up-to-date (version $CURRENT_NVM_VERSION)."
        fi
    else
        echo_color $RED "NVM not found. Skipping NVM update..."
    fi
    echo_color $ORANGE "====================================================================================\n"
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
			nvm install --lts --reinstall-packages-from="$CURRENT_NODE_VERSION" || {
				echo_color $RED "Failed to update Node.js."
				exit 1
			}

			# Switch to the latest Node.js version
			nvm use --lts || {
				echo_color $RED "Failed to switch to the latest Node.js version."
				exit 1
			}

			# Check the new current version after update
			NEW_NODE_VERSION=$(nvm current | sed 's/\x1b\[[0-9;]*m//g')

			# Uninstall the old version if it's different from the new version
			if [ "$NEW_NODE_VERSION" != "$CURRENT_NODE_VERSION" ]; then
				echo -e "${BLUE}Uninstalling the old version of Node.js${NC} ${PURPLE}${CURRENT_NODE_VERSION}${NC}..."
				nvm uninstall "$CURRENT_NODE_VERSION" || {
					echo_color $RED "Failed to uninstall the old version of Node.js."
					exit 1
				}
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
			echo_color $BLUE "Do you want to update npm global packages? (y/N)"
			# Set a 10-second timeout for user response
			read -r -t 10 update_choice
			if [[ $? -eq 0 ]] && [[ "$update_choice" == "y" || "$update_choice" == "Y" ]]; then
				echo_color $BLUE "Updating npm..."
				npm update -g || {
					echo_color $RED "Failed to update npm."
					exit 1
				}
			else
				echo_color $GREEN "Skipping npm update."
			fi
		else
			# Non-interactive mode (e.g., cron job)
			echo_color $BLUE "Updating npm in non-interactive mode..."
			npm update -g || {
				echo_color $RED "Failed to update npm."
				exit 1
			}
		fi
		echo_color $ORANGE "====================================================================================\n"
	else
		echo_color $RED "npm not found. Skipping..."
	fi
}

# Update pnpm packages
update_pnpm() {
	if command_exists pnpm; then
		echo_color $BLUE "Updating pnpm global packages..."
		pnpm -g up || {
			echo_color $RED "Failed to update pnpm packages."
			exit 1
		}
		echo_color $GREEN "pnpm global packages have been updated."
		echo_color $ORANGE "====================================================================================\n"
	else
		echo_color $RED "pnpm not found. Skipping..."
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
		nvim --headless "+TSUpdateSync" +qa

		# Check for differences
		echo_color $ORANGE "\nChecking for changes in lazy-lock.json..."
		local changes=$(diff -u "$backup_file" "$lazy_lock_file" | grep '^\+' | grep -v '^+++' | grep -v '^---')
		if [ -n "$changes" ]; then
			echo_color $GREEN "Changes detected in lazy-lock.json:"
			echo "$changes" | bat -l json
		else
			echo_color $BLUE "No changes detected in lazy-lock.json."
		fi

		echo_color $ORANGE "====================================================================================\n"
	else
		echo_color $RED "Neovim not found. Skipping AstroNvim update..."
	fi
}

# Update Java
update_java() {
	echo_color $BLUE "Updating Java JDK..."
	JDK_PAGE_URL="https://www.oracle.com/java/technologies/downloads/#jdk"

	# Fetch the page and extract the link
    JDK_URL=$(curl -sL $JDK_PAGE_URL | grep -oE 'https://download.oracle.com/java/[0-9]+/latest/jdk-[0-9]+_macos-aarch64_bin.tar.gz' | head -n 1)

	# If JDK_URL is not found, exit with error
	if [ -z "$JDK_URL" ]; then
    	echo_color $RED "Failed to find the latest JDK download link."
    	exit 1
	fi

	# Define the download and extraction location
	DOWNLOAD_LOCATION="$HOME/Downloads"
	EXTRACT_LOCATION="$DOWNLOAD_LOCATION/jdk_extract"

	# Create a directory to extract the tarball
	mkdir -p "$EXTRACT_LOCATION"

	# Download the tar.gz file to the extraction directory
	echo_color $ORANGE "Downloading and extracting JDK from $JDK_URL..."
	curl -L "$JDK_URL" | tar -xz -C "$EXTRACT_LOCATION"

	# Determine the name of the top-level directory in the extracted location
	JDK_DIR_NAME=$(ls "$EXTRACT_LOCATION" | grep 'jdk')

	# Check if this directory already exists in the target directory
	if [ ! -d "$HOME/Library/Java/JavaVirtualMachines/$JDK_DIR_NAME" ]; then
    	echo_color $GREEN "Installing Java..."
    	# Move the JDK directory to the Java Virtual Machines directory
    	mv "$EXTRACT_LOCATION/$JDK_DIR_NAME" "$HOME/Library/Java/JavaVirtualMachines/"
    	echo_color $GREEN "Java installed successfully."
	else
    	echo_color $BLUE "Java is already installed. No action taken, residual files have been removed."
    	# Remove the extracted JDK if already installed
    	rm -rf "$EXTRACT_LOCATION/$JDK_DIR_NAME"
	fi

	# Remove the extraction directory if empty
	rmdir "$EXTRACT_LOCATION"
	
	echo_color $ORANGE "====================================================================================\n"
}

# Update Ruby gems
update_gems() {
    if command_exists gem; then
        echo_color $BLUE "Updating Ruby gems..."
        gem update --system
        gem update
        gem cleanup
        echo_color $GREEN "Ruby gems have been updated."
        echo_color $ORANGE "====================================================================================\n"
    else
        echo_color $RED "Ruby gem command not found. Skipping gem update..."
    fi
}

# MAIN SCRIPT =====================================================================

# Function to manage log files
manage_log_files() {
	local log_dir="/Users/andreaventi/scripts/logs"
	local max_logs=14 # Set the maximum number of log files to keep

	echo_color $BLUE "Managing log files in scripts/logs..."
	cd "$log_dir"

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
		rm "${files_to_remove[@]}" # Remove the oldest log files
	else
		echo_color $BLUE "No log files need to be removed."
	fi

	cd -
}

# Send an email with the log file if the script is run non-interactively
send_update_report() {
	if [ -f "/Users/andreaventi/scripts/logs/upall_$(date +\%Y-\%m-\%d-\%IAM).log" ]; then
		LOG_FILE="/Users/andreaventi/scripts/logs/upall_$(date +\%Y-\%m-\%d-\%IAM).log"
	fi

	if [ -f "/Users/andreaventi/scripts/logs/upall_$(date +\%Y-\%m-\%d-\%IPM).log" ]; then
		LOG_FILE="/Users/andreaventi/scripts/logs/upall_$(date +\%Y-\%m-\%d-\%IPM).log"
	fi

	if [ -f "$LOG_FILE" ]; then
		{
			echo "To: andrea.venti12@gmail.com"
			echo "From: andrea.venti12@gmail.com"
			echo "Subject: Package Updater Output"
			echo ""
			echo -e "Package Updater Output for $(basename "$LOG_FILE")\n"
			cat "$LOG_FILE"
		} | msmtp -t
	else
		echo_color $RED "Log file not found: $LOG_FILE" >&2
	fi
}

# Main script execution
main() {
	update_homebrew
	remove_deleted_env_backups
	update_conda_environments
	backup_conda_environments
	update_tmux_plugins
	update_omz
	# update_mas
	update_nvm
	update_node
	update_npm
	update_pnpm
	# update_astronvim
	update_java
	update_gems
	gh extension upgrade gh-copilot
	echo_color $GREEN "All applicable packages and applications updated.\n"

	# Manage log files to keep only the most recent $max_logs
	manage_log_files

	# Post-update tasks
	if [ ! -t 0 ]; then
		send_update_report
	fi
}

main
