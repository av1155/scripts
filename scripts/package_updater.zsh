#!/bin/zsh

# This script updates all the installed packages/applications on the system.
# Dependencies: Homebrew (brew), miniforge (conda), Oh My Zsh (omz), Mac App Store CLI (mas), npm (Node.js)

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
	command -v "$1" >/dev/null 2>&1
}

# Function to update Homebrew
update_homebrew() {
	echo -e "${BLUE}Updating Homebrew...${NC}"
	brew update
	brew upgrade
	brew cleanup
	brew autoremove
}

# Function to update all conda environments
update_all_conda_envs() {
    echo -e "${BLUE}Updating all Conda environments...${NC}"
	conda update --all -y

    for env in $(conda env list | awk '{print $1}' | grep -vE '^\#|base'); do
        echo -e "${GREEN}Activating and updating $env...${NC}"
        source activate $env
        conda update --all -y
        conda deactivate
    done

    echo -e "${GREEN}All Conda environments have been updated.${NC}"
}

# Function to update Oh My Zsh
update_omz() {
	"$ZSH/tools/upgrade.sh"
}

# Function to update Mac App Store applications
update_mas() {
	echo -e "${BLUE}Updating Mac App Store applications...${NC}"
	mas outdated
	mas upgrade
}

# Function to update AstroNvim
update_astronvim() {
	echo -e "${BLUE}Updating AstroNvim...${NC}"
	nvim --headless "+Lazy sync" +qa
	nvim --headless "+TSUpdate" +qa
	nvim --headless "+AstroMasonUpdateAll" +qa
}

# Function to update Node.js using NVM
update_node() {
	# Your node update logic goes here, adapted from your first script
	# Ensure that NVM is loaded and then follow the logic to check for Node updates
	# This will include checking the current Node version, comparing with the latest LTS version, and updating if necessary
	echo -e "${BLUE}Updating Node.js...${NC}"

	# Get the current version of Node.js
	CURRENT_NODE_VERSION=$(nvm current | sed 's/\x1b\[[0-9;]*m//g')

	# Get the latest LTS Node.js version and strip ANSI escape codes
	LATEST_LTS_VERSION=$(nvm ls-remote --lts | tail -1 | awk '{ print $2 }' | sed 's/\x1b\[[0-9;]*m//g')

	# Debug: Print versions for checking
	echo "Current Node version:${PURPLE} ${CURRENT_NODE_VERSION} ${NC}"
	echo "Latest LTS version:${PURPLE} $(nvm ls-remote --lts | tail -1) ${NC}"

	if [ "$CURRENT_NODE_VERSION" != "$LATEST_LTS_VERSION" ]; then
    	# Install the latest LTS Node.js version and reinstall packages from the current version
    	nvm install --lts --reinstall-packages-from="$CURRENT_NODE_VERSION" || { echo -e "${RED}Failed to update Node.js.${NC}"; exit 1; }

    	# Switch to the latest Node.js version
    	nvm use --lts || { echo -e "${RED}Failed to switch to the latest Node.js version.${NC}"; exit 1; }

    	# Check the new current version after update
    	NEW_NODE_VERSION=$(nvm current | sed 's/\x1b\[[0-9;]*m//g')

    	# Uninstall the old version if it's different from the new version
    	if [ "$NEW_NODE_VERSION" != "$CURRENT_NODE_VERSION" ]; then
        	echo -e "${BLUE}Uninstalling the old version of Node.js${NC} ${PURPLE}${CURRENT_NODE_VERSION}${NC}..."
        	nvm uninstall "$CURRENT_NODE_VERSION" || { echo -e "${RED}Failed to uninstall the old version of Node.js.${NC}"; exit 1; }
    	fi

	else
		echo -e "${BLUE}Already on the latest LTS version of Node.js.${NC}"
	fi
}

# Function to update npm
update_npm() {
    echo -e "${BLUE}Do you want to update npm? (y/n)${NC}"
    read -r update_choice
    if [[ "$update_choice" == "y" || "$update_choice" == "Y" ]]; then
        echo -e "${BLUE}Updating npm...${NC}"
        npm update -g || { echo -e "${RED}Failed to update npm.${NC}"; exit 1; }
    else
        echo -e "${GREEN}Skipping npm update.${NC}"
    fi
}

# ==============================================

# Update Homebrew
if command_exists brew; then
	update_homebrew
	echo "" # Add a newline for better readability
else
	echo -e "${RED}Homebrew not found. Skipping...${NC}"
fi

# Update miniforge
if command_exists conda; then
	update_all_conda_envs
	echo "" # Add a newline for better readability
else
	echo -e "${RED}miniforge not found. Skipping...${NC}"
fi

# Update Oh My Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
	update_omz
	echo "" # Add a newline for better readability
else
	echo -e "${RED}Oh My Zsh not found. Skipping...${NC}"
fi

# Update Mac App Store applications
if command_exists mas; then
	update_mas
	echo "" # Add a newline for better readability
else
	echo -e "${RED}Mac App Store CLI not found. Skipping...${NC}"
fi

# Update Node.js using NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if command_exists nvm; then
    update_node
    echo "" # Add a newline for better readability
else
    echo -e "${RED}NVM not found. Skipping Node.js update...${NC}"
fi

# Update npm
if command_exists npm; then
	update_npm
	echo "" # Add a newline for better readability
else
	echo -e "${RED}npm not found. Skipping...${NC}"
fi

# Update AstroNvim
if command_exists nvim; then
	update_astronvim
	echo "" # Add a newline for better readability
else
	echo -e "${RED}Neovim not found. Skipping AstroNvim update...${NC}"
fi

echo -e "${GREEN}All applicable packages and applications updated.${NC}"