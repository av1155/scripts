#!/bin/bash

# This script updates all the installed packages/applications on the system.
# Dependencies: Homebrew (brew), miniforge (conda), Oh My Zsh (omz), Mac App Store CLI (mas), npm (Node.js)

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
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

# Function to update miniforge
update_miniforge() {
  echo -e "${BLUE}Updating miniforge...${NC}"
  conda update --all -y
}

# Function to update Oh My Zsh
update_omz() {
  echo -e "${BLUE}Updating Oh My Zsh...${NC}"
  sh "$HOME/.oh-my-zsh/tools/upgrade.sh"
}

# Function to update Mac App Store applications
update_mas() {
  echo -e "${BLUE}Updating Mac App Store applications...${NC}"
  mas outdated
  mas upgrade
}

# Function to update npm
update_npm() {
  echo -e "${BLUE}Updating npm...${NC}"
  npm update -g
}

# Function to update AstroNvim
update_astronvim() {
  echo -e "${BLUE}Updating AstroNvim...${NC}"
  nvim --headless "+Lazy! sync" +qa > astro_update.log 2>&1
  nvim --headless +MasonUpdateAll +qa > astro_update.log 2>&1
  bat astro_update.log
  rm astro_update.log
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
  update_miniforge
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

