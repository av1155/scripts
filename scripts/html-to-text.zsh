#!/bin/zsh

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to prompt for URL and output file
fetch_website_content() {

    # Check if lynx is installed
    if ! command -v lynx &>/dev/null; then
        echo -e "${RED}Error: 'lynx' is not installed. Please install it to continue.${NC}"
        return 1
    fi

    # Prompt for website URL
    echo -e "${BLUE}Enter the website URL: ${NC}"
    read website_url

    # Prompt for output file name
    echo -e "${BLUE}Enter the output file name + extension (example.txt): ${NC}"
    read output_file

    # Validate input
    if [[ -z "$website_url" || -z "$output_file" ]]; then
        echo -e "${RED}Error: Both URL and output file name are required!${NC}"
        return 1
    fi

    # Fetch and save the readable content using lynx
    echo -e "${YELLOW}Fetching content from '$website_url' and saving it to '$output_file'...${NC}"
    lynx -dump "$website_url" >"$output_file"

    # Check if the operation succeeded
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Content saved to '$output_file' successfully.${NC}"
    else
        echo -e "${RED}Failed to fetch content from '$website_url'.${NC}"
        return 1
    fi
}

# Call the function
fetch_website_content
