#!/bin/zsh

# Initialize Conda for script usage
if [ -f "/home/andreaventi/miniforge3/etc/profile.d/conda.sh" ]; then
    source "/home/andreaventi/miniforge3/etc/profile.d/conda.sh"
else
    echo "Conda initialization script not found. Exiting..."
    exit 1
fi

if [ -d "$HOME/.oh-my-zsh" ]; then
    export ZSH="$HOME/.oh-my-zsh"
    source "$ZSH/oh-my-zsh.sh"
else
    echo "Oh My Zsh initialization failed. Exiting..."
    exit 1
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

# Function to update apt packages and perform cleanup
update_apt() {
    echo_color $BLUE "Updating apt packages..."
    sudo apt update && sudo apt full-upgrade -y
    echo_color $GREEN "Cleaning up apt..."
    sudo apt autoremove -y && sudo apt clean
    echo_color $GREEN "\nAll apt packages have been updated and cleaned up."
    echo_color $ORANGE "====================================================================================\n"
}

# Function to update snap packages and perform cleanup
update_snap() {
    if command_exists snap; then
        echo_color $BLUE "Updating snap packages..."
        sudo snap refresh
        echo_color $GREEN "Cleaning up snap..."
        sudo snap set system refresh.retain=2
        echo_color $GREEN "\nAll snap packages have been updated and cleaned up."
        echo_color $ORANGE "====================================================================================\n"
    else
        echo_color $RED "Snap not found. Skipping..."
    fi
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
    if command_exists omz; then
        omz update
        echo_color $ORANGE "====================================================================================\n"
    else
        echo_color $RED "Oh My Zsh not found. Skipping..."
    fi
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
    else
        echo_color $RED "miniforge not found. Skipping..."
    fi
}

# Function to update tmux TPM plugins
update_tmux_plugins() {
    if [ -d "$HOME/.dotfiles/.config/tmux/plugins/tpm" ]; then
        echo_color $BLUE "Updating tmux TPM plugins..."
        "$HOME/.dotfiles/.config/tmux/plugins/tpm/scripts/update_plugin.sh" all
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
    update_snap
    update_gems
    update_cargo
    update_omz
    update_conda_environments
    backup_conda_environments
    update_tmux_plugins
    install_node_lts
    verify_node_install
    install_code_server
    gh extension upgrade gh-copilot
    echo_color $GREEN "All updates completed!"
    echo_color $ORANGE "====================================================================================\n"
}

# Execute the main function
main
