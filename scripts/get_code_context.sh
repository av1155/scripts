#!/bin/bash
# get_code_context.sh — Extract code context from a project into a single file
# v2.0.0

set -o pipefail

# ─── Colors (TTY-aware) ─────────────────────────────────────────────
init_colors() {
  if [[ -t 2 ]]; then
    bold="\033[1m" green="\033[32m" yellow="\033[33m"
    blue="\033[34m" red="\033[31m" magenta="\033[95m"
    dim="\033[2m" reset="\033[0m"
  else
    bold="" green="" yellow="" blue="" red="" magenta="" dim="" reset=""
  fi
}

# ─── Configuration ──────────────────────────────────────────────────
default_directories=(".")
default_extensions=(
  js ts tsx jsx html css scss
  py go java c cpp h hpp cs rb rs lua php
  sh zsh bash
  md txt
  json yaml yml toml
)

# Directories always excluded (applied to fd AND tree)
default_excluded_dirs=(
  node_modules .git vendor
  .next .nuxt .output .svelte-kit .angular
  __pycache__ .venv venv env .tox .mypy_cache .pytest_cache .ruff_cache .egg-info
  dist build out target coverage
  .idea .vscode .gradle .terraform .cache .parcel-cache .turbo
  bower_components .expo .metro .sass-cache
  .worktrees .opencode .claude .DS_Store
)

# File extensions always ignored (subtracted from search extensions)
default_ignore_exts=(
  ico png jpg jpeg gif svg bmp webp tiff avif heic heif
  out log tmp jar swp swo bak
  o a so dylib dll exe bin
  pyc pyo class
  woff woff2 ttf eot otf
  map lock
)

# Lock files always skipped (by exact basename)
lock_files=(
  package-lock.json yarn.lock pnpm-lock.yaml pnpm-lock.json
  Cargo.lock Gemfile.lock composer.lock poetry.lock
  Pipfile.lock go.sum bun.lockb flake.lock shrinkwrap.json
  uv.lock
)

MAX_FILE_SIZE="${MAX_FILE_SIZE:-1048576}"
output_file="codebase_context.txt"
include_no_extension="n"
no_extension_patterns=""

# ─── Utility Functions ──────────────────────────────────────────────
die()  { echo -e "${red}Error:${reset} $*" >&2; exit 1; }
warn() { echo -e "${yellow}Warning:${reset} $*" >&2; }

check_dependencies() {
  if command -v fd &>/dev/null; then
    USE_FD=true
  else
    USE_FD=false
    warn "fd not found — falling back to find (slower)"
  fi
  if command -v eza &>/dev/null; then
    TREE_CMD="eza"
  elif command -v tree &>/dev/null; then
    TREE_CMD="tree"
  else
    TREE_CMD="find"
    warn "Neither eza nor tree found — using find for directory listing"
  fi
}

is_binary() {
  # Empty files (e.g., __init__.py) are not binary
  local size
  size=$(stat -f%z -- "$1" 2>/dev/null || stat -c%s -- "$1" 2>/dev/null || echo 0)
  [[ "$size" -eq 0 ]] && return 1

  # Trust known text extensions — file(1) sometimes misidentifies them
  # (e.g., shell scripts with certain byte patterns flagged as "binary data")
  local ext="${1##*.}"
  if [[ "$ext" != "$1" ]]; then
    local known
    for known in "${effective_extensions[@]}"; do
      [[ "$ext" == "$known" ]] && return 1
    done
  fi

  local mime
  mime=$(file --mime-encoding --brief -- "$1" 2>/dev/null) || return 1
  [[ "$mime" == "binary" ]]
}

is_oversized() {
  local size
  size=$(stat -f%z -- "$1" 2>/dev/null || stat -c%s -- "$1" 2>/dev/null || echo 0)
  [[ "$size" -gt "$MAX_FILE_SIZE" ]]
}

is_lock_file() {
  local name="$1" lf
  for lf in "${lock_files[@]}"; do
    [[ "$name" == "$lf" ]] && return 0
  done
  return 1
}

human_size() {
  local bytes=$1
  if [[ $bytes -ge 1048576 ]]; then
    printf "%dMB" $((bytes / 1048576))
  elif [[ $bytes -ge 1024 ]]; then
    printf "%dKB" $((bytes / 1024))
  else
    printf "%dB" "$bytes"
  fi
}

generate_tree() {
  local ignore_glob
  ignore_glob=$(printf '%s|' "${all_excluded_dirs[@]}")
  ignore_glob+="*.log|*.tmp|*.swp|*.swo|*.ttf|*.woff|*.woff2|Icon?|${output_file}"

  case "$TREE_CMD" in
    eza)
      eza -A --git --icons=auto --tree --level=3 \
        --ignore-glob "$ignore_glob" "$(pwd)" 2>/dev/null \
        || eza -A --tree --level=3 \
          --ignore-glob "$ignore_glob" "$(pwd)" 2>/dev/null \
        || warn "eza tree failed"
      ;;
    tree)
      tree -a -L 3 -I "$ignore_glob" --noreport 2>/dev/null || warn "tree failed"
      ;;
    find)
      local find_args=(find . -maxdepth 3)
      local xdir
      for xdir in "${all_excluded_dirs[@]}"; do
        find_args+=(-not -path "*/${xdir}" -not -path "*/${xdir}/*")
      done
      find_args+=(-print)
      "${find_args[@]}" 2>/dev/null | sort | head -200
      ;;
  esac
}

process_file() {
  local display_path="$1"
  local full_path="$2"
  local basename="${display_path##*/}"

  # Skip the output file itself
  [[ "$full_path" == "$output_abs_path" ]] && return 0

  # Skip lock files
  if is_lock_file "$basename"; then
    skipped_lock=$((skipped_lock + 1))
    return 0
  fi

  # Skip oversized files (cheap stat check)
  if is_oversized "$full_path"; then
    skipped_size=$((skipped_size + 1))
    return 0
  fi

  # Skip binary files
  if is_binary "$full_path"; then
    skipped_binary=$((skipped_binary + 1))
    return 0
  fi

  # Append content
  {
    echo ""
    echo "<file path=\"$display_path\">"
    cat -- "$full_path"
    echo "</file>"
  } >> "$output_abs_path"

  file_count=$((file_count + 1))

  # Progress feedback on stderr
  if [[ -t 2 ]]; then
    printf "\r\033[K  \033[2m[%d files]\033[0m %s" "$file_count" "$display_path" >&2
  fi
}

# ─── Auto-Detect Project Type ───────────────────────────────────────
detect_project() {
  detected_types=()
  auto_extensions=()
  auto_no_extension=false
  auto_no_ext_patterns=()
  auto_extra_excludes=()

  # Node.js ecosystem
  if [[ -f "package.json" ]]; then
    detected_types+=("node")
    auto_extensions+=(js mjs cjs ts tsx jsx json css)

    if [[ -f "next.config.mjs" || -f "next.config.js" || -f "next.config.ts" ]]; then
      detected_types+=("next.js")
      auto_extensions+=(mdx scss)
    fi
    if [[ -f "vite.config.js" || -f "vite.config.ts" || -f "vite.config.mjs" ]]; then
      detected_types+=("vite")
      auto_extensions+=(html scss)
    fi
    if [[ -f "nuxt.config.ts" || -f "nuxt.config.js" ]]; then
      detected_types+=("nuxt")
      auto_extensions+=(vue scss html)
    fi
    if [[ -f "angular.json" ]]; then
      detected_types+=("angular")
      auto_extensions+=(html scss)
    fi
    if [[ -f "svelte.config.js" || -f "svelte.config.ts" ]]; then
      detected_types+=("svelte")
      auto_extensions+=(svelte html scss)
    fi
  fi

  # Python
  if [[ -f "pyproject.toml" || -f "setup.py" || -f "setup.cfg" || -f "requirements.txt" || -f "Pipfile" ]]; then
    detected_types+=("python")
    auto_extensions+=(py pyi toml cfg ini txt html css js)
  fi

  # Go
  if [[ -f "go.mod" ]]; then
    detected_types+=("go")
    auto_extensions+=(go mod)
  fi

  # Rust
  if [[ -f "Cargo.toml" ]]; then
    detected_types+=("rust")
    auto_extensions+=(rs toml)
  fi

  # Java / Kotlin
  if [[ -f "pom.xml" || -f "build.gradle" || -f "build.gradle.kts" ]]; then
    detected_types+=("java")
    auto_extensions+=(java kt kts xml gradle properties)
  fi

  # Ruby
  if [[ -f "Gemfile" || -f "Rakefile" ]]; then
    detected_types+=("ruby")
    auto_extensions+=(rb erb rake gemspec yml yaml)
    auto_no_extension=true
    auto_no_ext_patterns+=(Gemfile Rakefile Guardfile Procfile)
  fi

  # Lua / Neovim
  if [[ -f "init.lua" || -f "stylua.toml" ]] || { [[ -d "lua" ]] && [[ -f "lazy-lock.json" || -f "lazyvim.json" ]]; }; then
    detected_types+=("lua/neovim")
    auto_extensions+=(lua vim json toml)
  fi

  # Terraform
  if [[ -d "terraform" ]]; then
    detected_types+=("terraform")
    auto_extensions+=(tf tfvars hcl)
  fi

  # Ansible
  if [[ -d "ansible" || -f "ansible.cfg" ]]; then
    detected_types+=("ansible")
    auto_extensions+=(yml yaml j2 cfg)
  fi

  # Docker
  if [[ -f "Dockerfile" || -f "docker-compose.yml" || -f "docker-compose.yaml" || -f "docker-compose.dev.yml" ]]; then
    detected_types+=("docker")
    auto_extensions+=(yml yaml)
    auto_no_extension=true
    auto_no_ext_patterns+=(Dockerfile)
  fi

  # Kubernetes / Helm
  if [[ -d "kubernetes" || -d "k8s" || -d "charts" ]]; then
    detected_types+=("kubernetes")
    auto_extensions+=(yaml yml)
  fi

  # C / C++
  if [[ -f "CMakeLists.txt" || -f "Makefile" ]]; then
    detected_types+=("c/c++")
    auto_extensions+=(c cpp h hpp cmake mk)
    auto_no_extension=true
    auto_no_ext_patterns+=(Makefile)
  fi

  # Dotfiles / Stow
  if [[ -f ".stow-global-ignore" ]] || { [[ -f "install.sh" ]] && [[ -d "ZSH" || -d "zsh" ]]; }; then
    detected_types+=("dotfiles")
    auto_extensions+=(sh zsh bash json yaml yml toml conf cfg)
    auto_no_extension=true
    # For dotfiles, leave patterns empty → match ALL extensionless files
    auto_no_ext_patterns=()
    auto_extra_excludes+=(Fonts Java-Jars macOS-Library Local)
  fi

  # GitHub CI (additive)
  [[ -d ".github/workflows" ]] && auto_extensions+=(yml yaml)

  # Always include common documentation/config
  auto_extensions+=(md sh yml yaml json)

  # Deduplicate extensions
  local deduped=() ext found existing
  for ext in "${auto_extensions[@]}"; do
    found=false
    for existing in "${deduped[@]}"; do
      [[ "$ext" == "$existing" ]] && { found=true; break; }
    done
    [[ "$found" == "false" ]] && deduped+=("$ext")
  done
  auto_extensions=("${deduped[@]}")

  # Deduplicate no-ext patterns
  if [[ ${#auto_no_ext_patterns[@]} -gt 0 ]]; then
    local deduped_pats=() pat
    for pat in "${auto_no_ext_patterns[@]}"; do
      found=false
      for existing in "${deduped_pats[@]}"; do
        [[ "$pat" == "$existing" ]] && { found=true; break; }
      done
      [[ "$found" == "false" ]] && deduped_pats+=("$pat")
    done
    auto_no_ext_patterns=("${deduped_pats[@]}")
  fi
}

# ─── Help ───────────────────────────────────────────────────────────
show_help() {
  echo -e "${bold}get_code_context v2.0${reset}"
  echo -e "Extract code context from a project into a single text file."
  echo ""
  local cmd="${0##*/}"
  echo -e "${bold}Usage:${reset} ${cmd} [options]"
  echo ""
  echo -e "${bold}Options:${reset}"
  echo -e "  ${yellow}-a${reset}  Auto-detect project type and apply best config"
  echo -e "  ${yellow}-d${reset}  Directories to include (default: .)"
  echo -e "  ${yellow}-e${reset}  File extensions to include (default: js ts tsx jsx html css py go ...)"
  echo -e "  ${yellow}-i${reset}  File extensions to ignore (subtracted from -e list)"
  echo -e "  ${yellow}-x${reset}  Additional directories to exclude (merged with built-in exclusions)"
  echo -e "  ${yellow}-s${reset}  Max file size in bytes (default: 1048576 = 1MB)"
  echo -e "  ${yellow}-n${reset}  Include files without extensions"
  echo -e "  ${yellow}-p${reset}  Patterns for files without extensions (requires -n)"
  echo -e "  ${yellow}-o${reset}  Output file name (default: codebase_context.txt)"
  echo -e "  ${yellow}-h${reset}  Show this help message"
  echo ""
  echo -e "${bold}Auto mode (-a) detects:${reset}"
  echo -e "  ${dim}node, next.js, vite, nuxt, angular, svelte, python, go, rust, java,${reset}"
  echo -e "  ${dim}ruby, lua/neovim, terraform, ansible, docker, kubernetes, c/c++, dotfiles${reset}"
  echo ""
  echo -e "${bold}Built-in exclusions (always applied):${reset}"
  echo -e "  ${dim}Dirs: node_modules .git vendor dist build __pycache__ .venv coverage .next ...${reset}"
  echo -e "  ${dim}Skip: binary files, lock files (package-lock.json, yarn.lock, ...), files > 1MB${reset}"
  echo ""
  echo -e "${bold}Examples:${reset}"
  echo -e "  ${cmd} -a                           ${dim}# Auto-detect project type${reset}"
  echo -e "  ${cmd} -a -x tests                  ${dim}# Auto + exclude a dir${reset}"
  echo -e "  ${cmd} -e 'py toml yaml'            ${dim}# Specific extensions only${reset}"
  echo -e "  ${cmd} -d src -n                     ${dim}# Scan dir, include no-ext files${reset}"
  echo -e "  ${cmd}                               ${dim}# Interactive mode${reset}"
}

# ═══════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════
init_colors
check_dependencies

# ─── Parse Options ──────────────────────────────────────────────────
directories=("${default_directories[@]}")
extensions=("${default_extensions[@]}")
ignore_exts=("${default_ignore_exts[@]}")
user_excluded_dirs=()
interactive=false
auto_mode=false
user_set_extensions=false

while getopts "ad:e:i:x:p:o:s:nh" flag; do
  case "${flag}" in
    a) auto_mode=true ;;
    d) IFS=' ' read -ra directories <<< "${OPTARG}" ;;
    e) user_set_extensions=true; IFS=' ' read -ra extensions <<< "${OPTARG}" ;;
    i) IFS=' ' read -ra ignore_exts <<< "${OPTARG}" ;;
    x) IFS=' ' read -ra user_excluded_dirs <<< "${OPTARG}" ;;
    s) MAX_FILE_SIZE="${OPTARG}" ;;
    o) output_file="${OPTARG}" ;;
    n) include_no_extension="y" ;;
    p) no_extension_patterns="${OPTARG}" ;;
    h) show_help; exit 0 ;;
    *) echo -e "${red}Invalid option. Use -h for help.${reset}" >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

[[ $OPTIND -eq 1 ]] && interactive=true

# Validate
[[ "$MAX_FILE_SIZE" =~ ^[0-9]+$ ]] || die "Invalid file size: $MAX_FILE_SIZE"

# ─── Interactive Mode ───────────────────────────────────────────────
if [[ "$interactive" == true ]]; then
  project_name=$(basename "$(pwd)")

  echo "" >&2
  echo -e "  ${bold}get_code_context${reset} ${dim}— ${project_name}${reset}" >&2
  echo -e "  ${blue}─────────────────────────────────────────────${reset}" >&2
  echo "" >&2

  # Auto-detect project type
  detect_project

  if [[ ${#detected_types[@]} -gt 0 ]]; then
    # ─── Auto-detected ─────────────────────────────────────────
    echo -e "  ${green}Detected:${reset}    ${bold}${detected_types[*]}${reset}" >&2
    echo -e "  ${dim}Extensions:${reset}  ${auto_extensions[*]}" >&2
    if [[ "$auto_no_extension" == true ]]; then
      if [[ ${#auto_no_ext_patterns[@]} -gt 0 ]]; then
        echo -e "  ${dim}No-ext:${reset}      ${auto_no_ext_patterns[*]}" >&2
      else
        echo -e "  ${dim}No-ext:${reset}      all extensionless files" >&2
      fi
    fi
    echo "" >&2

    read -rp "$(echo -e "  ${yellow}▸${reset} Use this config? ${dim}[Y/n]:${reset} ")" use_auto
    use_auto="${use_auto:-Y}"

    if [[ "$use_auto" =~ ^[Yy]$ ]]; then
      # Accept auto config
      extensions=("${auto_extensions[@]}")
      if [[ "$auto_no_extension" == true ]]; then
        include_no_extension="y"
        if [[ ${#auto_no_ext_patterns[@]} -gt 0 ]]; then
          no_extension_patterns="${auto_no_ext_patterns[*]}"
        fi
      fi
      for d in "${auto_extra_excludes[@]}"; do
        user_excluded_dirs+=("$d")
      done

      echo "" >&2
      extra_xdirs=()
      read -rp "$(echo -e "  ${yellow}▸${reset} Extra dirs to exclude ${dim}(optional):${reset} ")" input_xdirs
      if [[ -n "$input_xdirs" ]]; then
        IFS=' ' read -ra extra_xdirs <<< "$input_xdirs"
        user_excluded_dirs+=("${extra_xdirs[@]}")
      fi

      # Build rerun command
      rerun="getc -a"
      [[ ${#extra_xdirs[@]} -gt 0 ]] && rerun+=" -x '${extra_xdirs[*]}'"
      [[ "$output_file" != "codebase_context.txt" ]] && rerun+=" -o '${output_file}'"

    else
      # Manual override — auto values used as defaults
      echo "" >&2

      read -rp "$(echo -e "  ${yellow}▸${reset} Directories to scan ${dim}(default: .):${reset} ")" input_dirs
      [[ -n "$input_dirs" ]] && IFS=' ' read -ra directories <<< "$input_dirs"

      read -rp "$(echo -e "  ${yellow}▸${reset} File extensions ${dim}(Enter = auto):${reset} ")" input_exts
      if [[ -n "$input_exts" ]]; then
        IFS=' ' read -ra extensions <<< "$input_exts"
      else
        extensions=("${auto_extensions[@]}")
      fi

      read -rp "$(echo -e "  ${yellow}▸${reset} Extensions to ignore ${dim}(optional):${reset} ")" input_ign
      [[ -n "$input_ign" ]] && IFS=' ' read -ra ignore_exts <<< "$input_ign"

      read -rp "$(echo -e "  ${yellow}▸${reset} Dirs to exclude ${dim}(optional):${reset} ")" input_xdirs
      [[ -n "$input_xdirs" ]] && IFS=' ' read -ra user_excluded_dirs <<< "$input_xdirs"

      read -rp "$(echo -e "  ${yellow}▸${reset} Include extensionless files? ${dim}[y/N]:${reset} ")" include_no_extension
      include_no_extension="${include_no_extension:-n}"
      if [[ "$include_no_extension" == "y" ]]; then
        read -rp "$(echo -e "  ${yellow}▸${reset} No-ext patterns ${dim}(optional, blank=all):${reset} ")" no_extension_patterns
      fi

      # Build rerun command
      rerun="getc"
      [[ "${directories[*]}" != "." ]] && rerun+=" -d '${directories[*]}'"
      [[ "${extensions[*]}" != "${default_extensions[*]}" ]] && rerun+=" -e '${extensions[*]}'"
      [[ -n "${input_ign:-}" ]] && rerun+=" -i '${ignore_exts[*]}'"
      [[ ${#user_excluded_dirs[@]} -gt 0 ]] && rerun+=" -x '${user_excluded_dirs[*]}'"
      [[ "$include_no_extension" == "y" ]] && rerun+=" -n"
      [[ -n "$no_extension_patterns" ]] && rerun+=" -p '${no_extension_patterns}'"
      [[ "$output_file" != "codebase_context.txt" ]] && rerun+=" -o '${output_file}'"
    fi

  else
    # ─── No detection — full manual mode ────────────────────────
    echo -e "  ${dim}No project type detected — manual mode${reset}" >&2
    echo "" >&2

    read -rp "$(echo -e "  ${yellow}▸${reset} Directories to scan ${dim}(default: .):${reset} ")" input_dirs
    [[ -n "$input_dirs" ]] && IFS=' ' read -ra directories <<< "$input_dirs"

    read -rp "$(echo -e "  ${yellow}▸${reset} File extensions: ")" input_exts
    [[ -n "$input_exts" ]] && IFS=' ' read -ra extensions <<< "$input_exts"

    read -rp "$(echo -e "  ${yellow}▸${reset} Extensions to ignore ${dim}(optional):${reset} ")" input_ign
    [[ -n "$input_ign" ]] && IFS=' ' read -ra ignore_exts <<< "$input_ign"

    read -rp "$(echo -e "  ${yellow}▸${reset} Dirs to exclude ${dim}(optional):${reset} ")" input_xdirs
    [[ -n "$input_xdirs" ]] && IFS=' ' read -ra user_excluded_dirs <<< "$input_xdirs"

    read -rp "$(echo -e "  ${yellow}▸${reset} Include extensionless files? ${dim}[y/N]:${reset} ")" include_no_extension
    include_no_extension="${include_no_extension:-n}"
    if [[ "$include_no_extension" == "y" ]]; then
      read -rp "$(echo -e "  ${yellow}▸${reset} No-ext patterns ${dim}(optional, blank=all):${reset} ")" no_extension_patterns
    fi

    # Build rerun command
    rerun="getc"
    [[ "${directories[*]}" != "." ]] && rerun+=" -d '${directories[*]}'"
    [[ "${extensions[*]}" != "${default_extensions[*]}" ]] && rerun+=" -e '${extensions[*]}'"
    [[ -n "${input_ign:-}" ]] && rerun+=" -i '${ignore_exts[*]}'"
    [[ ${#user_excluded_dirs[@]} -gt 0 ]] && rerun+=" -x '${user_excluded_dirs[*]}'"
    [[ "$include_no_extension" == "y" ]] && rerun+=" -n"
    [[ -n "$no_extension_patterns" ]] && rerun+=" -p '${no_extension_patterns}'"
    [[ "$output_file" != "codebase_context.txt" ]] && rerun+=" -o '${output_file}'"
  fi

  # ─── Summary ──────────────────────────────────────────────────
  echo "" >&2
  echo -e "  ${blue}─── Config ──────────────────────────────────${reset}" >&2
  echo -e "  ${dim}Scan:${reset}        ${directories[*]}" >&2
  echo -e "  ${dim}Extensions:${reset}  ${extensions[*]}" >&2
  if [[ "$include_no_extension" == "y" ]]; then
    if [[ -n "$no_extension_patterns" ]]; then
      echo -e "  ${dim}No-ext:${reset}      ${no_extension_patterns}" >&2
    else
      echo -e "  ${dim}No-ext:${reset}      all" >&2
    fi
  fi
  if [[ ${#user_excluded_dirs[@]} -gt 0 ]]; then
    echo -e "  ${dim}+ Exclude:${reset}   ${user_excluded_dirs[*]}" >&2
  fi
  echo -e "  ${dim}Output:${reset}      ${output_file}" >&2
  echo -e "  ${blue}─────────────────────────────────────────────${reset}" >&2
  echo -e "  ${dim}Rerun:${reset} ${bold}${rerun}${reset}" >&2
  echo "" >&2
fi

# ─── Auto Mode ──────────────────────────────────────────────────────
if [[ "$auto_mode" == true ]]; then
  detect_project

  if [[ ${#detected_types[@]} -eq 0 ]]; then
    warn "Could not detect project type — using default extensions"
  else
    echo -e "${green}Detected:${reset} ${bold}${detected_types[*]}${reset}" >&2

    # Use auto-detected extensions unless user explicitly set -e
    if [[ "$user_set_extensions" == false ]]; then
      extensions=("${auto_extensions[@]}")
    fi

    # Enable no-extension mode if auto-detect wants it
    if [[ "$auto_no_extension" == true && "$include_no_extension" != "y" ]]; then
      include_no_extension="y"
      if [[ ${#auto_no_ext_patterns[@]} -gt 0 ]]; then
        no_extension_patterns="${auto_no_ext_patterns[*]}"
      fi
    fi

    # Add auto-detected extra directory exclusions
    for d in "${auto_extra_excludes[@]}"; do
      user_excluded_dirs+=("$d")
    done

    echo -e "${blue}Extensions:${reset} ${extensions[*]}" >&2
    if [[ "$include_no_extension" == "y" ]]; then
      if [[ -n "$no_extension_patterns" ]]; then
        echo -e "${blue}No-ext files:${reset} ${no_extension_patterns}" >&2
      else
        echo -e "${blue}No-ext files:${reset} all" >&2
      fi
    fi
    echo "" >&2
  fi
fi

# ─── Merge Exclusions ──────────────────────────────────────────────
all_excluded_dirs=("${default_excluded_dirs[@]}")
for d in "${user_excluded_dirs[@]}"; do
  all_excluded_dirs+=("$d")
done

# Build effective extensions (subtract ignore list)
effective_extensions=()
for ext in "${extensions[@]}"; do
  skip=false
  for ign in "${ignore_exts[@]}"; do
    [[ "$ext" == "$ign" ]] && { skip=true; break; }
  done
  [[ "$skip" == "false" ]] && effective_extensions+=("$ext")
done

[[ ${#effective_extensions[@]} -eq 0 ]] && die "No extensions remain after applying ignore list"

# ─── Output File Setup ─────────────────────────────────────────────
project_dir=$(pwd)
output_abs_path="${project_dir}/${output_file}"

# Remove old output file
[[ -f "$output_abs_path" ]] && rm -f -- "$output_abs_path"

# Write header + tree
{
  echo "<project_structure>"
} > "$output_abs_path"

generate_tree >> "$output_abs_path"

{
  echo "</project_structure>"
  echo ""
  echo "<files>"
} >> "$output_abs_path"

# ─── Traps ──────────────────────────────────────────────────────────
cleanup() { [[ -t 2 ]] && printf "\r\033[K" >&2; }
trap cleanup EXIT
trap 'echo -e "\n${red}Interrupted.${reset}" >&2; exit 130' INT TERM

# ─── Timer + Counters ──────────────────────────────────────────────
SECONDS=0
file_count=0
skipped_binary=0
skipped_size=0
skipped_lock=0

# ─── Helper: resolve display and full paths ─────────────────────────
resolve_paths() {
  local dir="$1" file="$2"
  if [[ "$dir" == "." ]]; then
    _display="$file"
    _full="${project_dir}/${file}"
  elif [[ "$dir" == /* ]]; then
    _display="${dir}/${file}"
    _full="${dir}/${file}"
  else
    _display="${dir}/${file}"
    _full="${project_dir}/${dir}/${file}"
  fi
}

# ─── Scan ───────────────────────────────────────────────────────────
for dir in "${directories[@]}"; do
  if [[ ! -d "$dir" ]]; then
    warn "Directory '$dir' does not exist — skipping."
    continue
  fi

  echo -e "${bold}${magenta}\nScanning files with extensions in ${dir}...${reset}" >&2

  if [[ "$USE_FD" == true ]]; then
    # Build fd arguments
    fd_args=(--hidden --type f)
    for ext in "${effective_extensions[@]}"; do
      fd_args+=(--extension "$ext")
    done
    for xdir in "${all_excluded_dirs[@]}"; do
      fd_args+=(--exclude "$xdir")
    done
    fd_args+=(--exclude "$output_file")

    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      resolve_paths "$dir" "$file"
      process_file "$_display" "$_full"
    done < <(cd "$dir" && fd "${fd_args[@]}" . 2>/dev/null)
  else
    # find fallback
    find_args=(. -type f)
    for xdir in "${all_excluded_dirs[@]}"; do
      find_args+=(-not -path "*/${xdir}/*" -not -path "*/${xdir}")
    done
    find_args+=(-not -name "$output_file")

    # Extension filter
    find_args+=("(")
    first_ext=true
    for ext in "${effective_extensions[@]}"; do
      if [[ "$first_ext" == true ]]; then
        find_args+=(-name "*.$ext")
        first_ext=false
      else
        find_args+=(-o -name "*.$ext")
      fi
    done
    find_args+=(")")

    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      file="${file#./}"
      resolve_paths "$dir" "$file"
      process_file "$_display" "$_full"
    done < <(cd "$dir" && find "${find_args[@]}" 2>/dev/null)
  fi

  # ─── No-extension scan ─────────────────────────────────────────
  if [[ "$include_no_extension" == "y" ]]; then
    echo -e "${bold}${magenta}Scanning files without extensions in ${dir}...${reset}" >&2

    if [[ "$USE_FD" == true ]]; then
      fd_noext_args=(--hidden --type f)
      for xdir in "${all_excluded_dirs[@]}"; do
        fd_noext_args+=(--exclude "$xdir")
      done
      fd_noext_args+=(--exclude "$output_file")

      if [[ -z "$no_extension_patterns" ]]; then
        fd_noext_args+=(--regex '(^|/)[^./]+$')
      else
        IFS=' ' read -ra patterns <<< "$no_extension_patterns"
        regex=$(IFS='|'; echo "(${patterns[*]})")
        fd_noext_args+=(--regex "(^|/)${regex}$")
      fi

      while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        resolve_paths "$dir" "$file"
        process_file "$_display" "$_full"
      done < <(cd "$dir" && fd "${fd_noext_args[@]}" . 2>/dev/null)
    else
      # find fallback for no-extension files
      find_noext_args=(. -type f)
      for xdir in "${all_excluded_dirs[@]}"; do
        find_noext_args+=(-not -path "*/${xdir}/*" -not -path "*/${xdir}")
      done
      find_noext_args+=(-not -name "$output_file")

      if [[ -z "$no_extension_patterns" ]]; then
        find_noext_args+=(-not -name "*.*")
      else
        find_noext_args+=("(")
        first_pat=true
        IFS=' ' read -ra patterns <<< "$no_extension_patterns"
        for pat in "${patterns[@]}"; do
          if [[ "$first_pat" == true ]]; then
            find_noext_args+=(-name "$pat")
            first_pat=false
          else
            find_noext_args+=(-o -name "$pat")
          fi
        done
        find_noext_args+=(")")
      fi

      while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        file="${file#./}"
        resolve_paths "$dir" "$file"
        process_file "$_display" "$_full"
      done < <(cd "$dir" && find "${find_noext_args[@]}" 2>/dev/null)
    fi
  fi
done

# Close files tag
echo "" >> "$output_abs_path"
echo "</files>" >> "$output_abs_path"

# ─── Summary ────────────────────────────────────────────────────────
[[ -t 2 ]] && printf "\r\033[K" >&2

echo "" >&2
echo -e "${green}Code context saved to ${output_abs_path}${reset}" >&2
echo -e "${blue}Files included:${reset} ${file_count}" >&2
[[ $skipped_binary -gt 0 ]] && echo -e "${yellow}Binary files skipped:${reset} ${skipped_binary}" >&2
[[ $skipped_size -gt 0 ]] && echo -e "${yellow}Oversized files skipped:${reset} ${skipped_size}" >&2
[[ $skipped_lock -gt 0 ]] && echo -e "${yellow}Lock files skipped:${reset} ${skipped_lock}" >&2

if [[ -f "$output_abs_path" ]]; then
  out_size=$(stat -f%z -- "$output_abs_path" 2>/dev/null || stat -c%s -- "$output_abs_path" 2>/dev/null || echo 0)
  echo -e "${blue}Output size:${reset} $(human_size "$out_size")" >&2
fi

elapsed=$SECONDS
if [[ $elapsed -eq 0 ]]; then
  echo -e "${blue}Execution time:${reset} <1s" >&2
else
  echo -e "${blue}Execution time:${reset} ${elapsed}s" >&2
fi
