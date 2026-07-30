#!/bin/zsh

# Package Updater
# A script to update Homebrew packages, tmux plugins, Oh My Zsh, and pnpm-managed global Node.js tooling.

# If the script is run non-interactively (e.g., cron job), set the PATH and ZSH variables
if [ ! -t 0 ]; then
	# Set the PATH to include Homebrew's bin directory and system paths
	export PATH="/opt/homebrew/bin:$PATH"

	# Set the ZSH variable to the Oh My Zsh directory
	export ZSH="/Users/andreaventi/.oh-my-zsh"

	# Ensure Homebrew Ruby is prioritized over system Ruby
	export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
fi

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
		brew autoremove
		brew cleanup --prune=all
		brew doctor || echo_color $ORANGE "brew doctor reported warnings (non-fatal)."
		cd "$HOME/.dotfiles/App-Configs/configs/MacOS-Bootstrap"
		rm Brewfile
		brew bundle dump --describe

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

# Update pnpm-managed global packages (node itself comes from Homebrew)
update_pnpm_globals() {
	if command_exists pnpm; then
		echo_color $BLUE "Updating pnpm global packages..."
		pnpm -g up || echo_color $RED "Failed to update pnpm packages."

		echo_color $GREEN "pnpm globals updated."
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
			echo "From: notifier.homelab@gmail.com"
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
	update_tmux_plugins
	update_omz
	update_pnpm_globals
	# update_astronvim
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
