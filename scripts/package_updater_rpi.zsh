#!/bin/bash

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

# Function to update apt packages and perform cleanup
update_apt() {
    echo_color $BLUE "Updating apt packages..."
    sudo apt update && sudo apt full-upgrade -y
    echo_color $GREEN "Cleaning up apt..."
    sudo apt autoremove -y && sudo apt clean
    echo_color $GREEN "\nAll apt packages have been updated and cleaned up."
    echo_color $ORANGE "====================================================================================\n"
}

# Function to update Ruby gems and perform cleanup
update_gems() {
    if command_exists gem; then
        echo_color $BLUE "Updating Ruby gems..."
        sudo gem update
        echo_color $GREEN "Cleaning up gem..."
        sudo gem cleanup
        echo_color $GREEN "\nAll Ruby gems have been updated and cleaned up."
        echo_color $ORANGE "====================================================================================\n"
    else
        echo_color $RED "Ruby gems not found. Skipping..."
    fi
}

# Function to update Cargo packages and perform cleanup
update_cargo() {
    if command_exists cargo; then
        echo_color $BLUE "Updating Cargo packages..."
        cargo install-update --all

        echo_color $GREEN "Cleaning up Cargo registry..."
        if ! command_exists cargo-cache; then
            cargo install cargo-cache
        fi
        cargo cache --autoclean
        echo_color $GREEN "\nAll Cargo packages have been updated and registry cleaned up."
        echo_color $ORANGE "====================================================================================\n"
    else
        echo_color $RED "Cargo not found. Skipping..."
    fi
}

# Update Oh My Zsh
update_omz() {
	if [ -d "$HOME/.oh-my-zsh" ]; then
		"$ZSH/tools/upgrade.sh"
		"$ZSH/tools/changelog.sh"
		echo_color $GREEN "\nOh My Zsh has been updated."
		echo_color $ORANGE "====================================================================================\n"
	else
		echo_color $RED "Oh My Zsh not found. Skipping..."
	fi
}

# Function to update all Conda environments, including the base environment
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

		echo_color $GREEN "\nAll Conda environments have been updated."
		echo_color $ORANGE "====================================================================================\n"
	else
		echo_color $RED "miniforge not found. Skipping..."
	fi
}

# Backup Conda environments
backup_conda_environments() {
	if command_exists conda; then
		BACKUP_DIR="${HOME}/CondaBackup-RPI"

		# Check if the backup directory exists
		if [ ! -d "$BACKUP_DIR" ]; then
			echo_color $BLUE "CondaBackup directory not found. Cloning from GitHub..."
			git clone https://github.com/av1155/CondaBackup-RPI.git "$BACKUP_DIR" || {
				echo_color $RED "Failed to clone CondaBackup-RPI repository."
				exit 1
			}
		fi

		echo_color $BLUE "Backing up all Conda environments to $BACKUP_DIR..."

		for env in $(conda env list | awk '{print $1}' | grep -vE '^\#'); do
			echo_color $GREEN "\nBacking up environment $env..."
			conda env export --name "$env" >"$BACKUP_DIR/${env}.yml"
		done

		echo_color $GREEN "\nAll Conda environments have been backed up to $BACKUP_DIR."
		echo_color $ORANGE "====================================================================================\n"
	else
		echo_color $RED "miniforge not found. Skipping..."
	fi
}

# Function to install Node.js LTS and perform cleanup
install_node_lts() {
    if command_exists curl; then
        echo_color $BLUE "Installing Node.js LTS..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x -o nodesource_setup.sh
        sudo bash nodesource_setup.sh
        sudo apt-get install -y nodejs
        rm nodesource_setup.sh
        echo_color $GREEN "Cleaning up apt..."
        sudo apt autoremove -y && sudo apt clean
        echo_color $GREEN "\nNode.js LTS has been installed and apt cleaned up."
        echo_color $ORANGE "====================================================================================\n"
    else
        echo_color $RED "curl not found. Skipping Node.js installation..."
    fi
}

# Function to verify Node.js installation
verify_node_install() {
    if command_exists node; then
        echo_color $BLUE "Verifying Node.js installation..."
        node -v
        echo_color $GREEN "\nNode.js installation verified."
        echo_color $ORANGE "====================================================================================\n"
    else
        echo_color $RED "Node.js not found. Skipping verification..."
    fi
}

# Function to install or update code-server
install_code_server() {
    if command_exists curl; then
        echo_color $BLUE "Installing or updating code-server..."
        curl -fsSL https://code-server.dev/install.sh | sh
        sudo systemctl enable --now code-server@$USER
        echo_color $GREEN "\ncode-server has been installed or updated."
        echo_color $ORANGE "====================================================================================\n"
    else
        echo_color $RED "curl not found. Skipping code-server installation..."
    fi
}

# MAIN SCRIPT =====================================================================

# Main function to call all update functions
main() {
    echo_color $PURPLE "Starting Raspberry Pi 5 Package Updater..."
    update_apt
    update_gems
    update_cargo
    update_omz
    update_conda_environments
    backup_conda_environments
    install_node_lts
    verify_node_install
    install_code_server
    gh extension upgrade gh-copilot
    echo_color $GREEN "All updates completed!"
    echo_color $ORANGE "====================================================================================\n"
}

# Execute the main function
main

