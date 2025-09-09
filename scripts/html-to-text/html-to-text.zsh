#!/bin/zsh

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Helpers ---

percent_decode() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//%/\\x}"
    # shellcheck disable=SC2059
    printf '%b' "$s"
}

sanitize_filename() {
    local s="$1"
    s="${s//[[:space:]]/_}"
    s="$(printf '%s' "$s" | tr -cd '[:alnum:]._-\n')"
    if [[ -z "$s" ]]; then
        s="output-$(date +%Y%m%d-%H%M%S)"
    fi
    printf '%s' "$s"
}

basename_from_url() {
    local url="$1" base last
    url="${url%%\?*}"
    url="${url%%\#*}"
    base="${url%/}"
    last="$(basename "$base")"

    if [[ -z "$last" || "$last" == "/" ]]; then
        printf 'output-%s' "$(date +%Y%m%d-%H%M%S)"
        return
    fi

    last="$(percent_decode "$last")"
    while [[ "$last" == *.* ]]; do
        last="${last%.*}"
    done
    last="$(sanitize_filename "$last")"
    if [[ -z "$last" ]]; then
        last="output-$(date +%Y%m%d-%H%M%S)"
    fi
    printf '%s' "$last"
}

choose_converter() {
    if command -v pandoc &>/dev/null; then
        echo "pandoc md"
    elif command -v w3m &>/dev/null; then
        echo "w3m txt"
    elif command -v lynx &>/dev/null; then
        echo "lynx txt"
    else
        echo "none txt"
    fi
}

base_from_url() {
    local u="$1"
    u="${u%%\#*}"
    u="${u%%\?*}" # strip fragment/query
    if [[ "$u" != */ ]]; then u="${u%/*}/"; fi
    printf '%s' "$u"
}

script_dir() {
    local s="${0:A:h}"
    printf '%s' "$s"
}

detect_base_href() {
    # reads HTML on stdin, prints detected base or empty
    awk 'BEGIN{ IGNORECASE=1 }
         match($0, /<base[^>]*href=["\047]([^"\047]+)["\047]/, m) { print m[1]; exit }'
}

# --- Main ---

fetch_website_content() {
    if ! command -v curl &>/dev/null; then
        echo -e "${RED}Error: 'curl' is not installed. Please install it to continue.${NC}"
        return 1
    fi

    echo -e "${BLUE}Enter the website URL: ${NC}"
    read website_url
    if [[ -z "$website_url" ]]; then
        echo -e "${RED}Error: URL is required!${NC}"
        return 1
    fi

    read converter def_ext <<<"$(choose_converter)"
    if [[ "$converter" == "none" ]]; then
        echo -e "${RED}No converter found. Install one of: pandoc (recommended), w3m, or lynx.${NC}"
        return 1
    fi

    base="$(basename_from_url "$website_url")"
    suggested_file="${base}.${def_ext}"

    echo -e "${BLUE}Enter the output file name (default: $suggested_file): ${NC}"
    read output_file
    if [[ -z "$output_file" ]]; then
        output_file="$suggested_file"
    fi

    if [[ "$output_file" != *.* ]]; then
        output_file="${output_file}.${def_ext}"
    fi

    echo -e "${YELLOW}Fetching and converting '$website_url' → '$output_file'...${NC}"

    case "$converter" in
    pandoc)
        local filter_path
        filter_path="$HOME/scripts/scripts/html-to-text/abs.lua"

        local html
        html="$(curl -fsSL "$website_url")" || {
            echo -e "${RED}fetch failed.${NC}"
            return 1
        }

        # Prefer <base href="..."> if present
        local detected_base
        detected_base="$(printf '%s' "$html" | detect_base_href 2>/dev/null)"
        if [[ -n "$detected_base" ]]; then
            BASE_URL="$(base_from_url "$detected_base")"
        else
            BASE_URL="$(base_from_url "$website_url")"
        fi

        if ! printf '%s' "$html" | BASE_URL="$BASE_URL" pandoc -f html -t gfm --reference-links --wrap=none \
            --lua-filter="$filter_path" -o "$output_file"; then
            echo -e "${RED}pandoc conversion failed.${NC}"
            return 1
        fi
        ;;
    w3m)
        echo -e "${YELLOW}Note: URLs won’t be absolutized with w3m.${NC}"
        if ! w3m -dump -cols 10000 "$website_url" >"$output_file"; then
            echo -e "${RED}w3m conversion failed.${NC}"
            return 1
        fi
        ;;
    lynx)
        echo -e "${YELLOW}Note: URLs won’t be absolutized with lynx.${NC}"
        if ! lynx -dump -width=10000 "$website_url" |
            sed -E 's/^[[:space:]]{2,}//' >"$output_file"; then
            echo -e "${RED}lynx conversion failed.${NC}"
            return 1
        fi
        ;;
    esac

    echo -e "${GREEN}Content saved to '$output_file' successfully.${NC}"

    # --- Offer to open the file in browser ---
    echo -n "Open in browser? [Y/n]: "
    read reply
    reply=${reply:l} # to lowercase
    if [[ -z "$reply" || "$reply" == "y" || "$reply" == "yes" ]]; then
        if [[ "$output_file" == *.md ]]; then
            # Render Markdown to a temp HTML file
            tmp_html="/tmp/$(basename "${output_file%.md}").html"
            if pandoc "$output_file" -s \
                --css=https://cdn.jsdelivr.net/npm/github-markdown-css/github-markdown.min.css \
                -o "$tmp_html"; then
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    open "$tmp_html"
                else
                    xdg-open "$tmp_html" >/dev/null 2>&1 &
                fi
            else
                echo -e "${RED}Failed to generate HTML preview with pandoc.${NC}"
            fi
        else
            # For non-Markdown output, just try to open directly
            if [[ "$OSTYPE" == "darwin"* ]]; then
                open "$output_file"
            else
                xdg-open "$output_file" >/dev/null 2>&1 &
            fi
        fi
    fi
}

fetch_website_content
