# Scripts Collection

A versatile collection of scripts designed for developers and system administrators to enhance productivity and streamline workflows. This repository includes utilities for managing Java projects, initializing Maven projects, compiling C programs, updating packages, and more.

---

<!--toc:start-->

-   [Scripts Collection](#scripts-collection)
    -   [Table of Contents](#table-of-contents)
    -   [Scripts](#scripts)
        -   [JavaProjectManager](#javaprojectmanager)
        -   [MavenJavaProjectInitializer](#mavenjavaprojectinitializer)
        -   [C Compiler](#c-compiler)
        -   [Get Code Context](#get-code-context)
        -   [HTML to Text Converter](#html-to-text-converter)
        -   [Image Previewer (imgp)](#image-previewer-imgp)
        -   [Neovim Surround Usage Guide](#neovim-surround-usage-guide)
        -   [Package Updater](#package-updater)
        -   [Package Updater for Raspberry Pi](#package-updater-for-raspberry-pi)
        -   [SQL URL Generator](#sql-url-generator)
        -   [Tmux Shortpath](#tmux-shortpath)
    -   [Installation](#installation)
        -   [For the JavaProjectManager, a Homebrew formula is available:](#for-the-javaprojectmanager-a-homebrew-formula-is-available)
    -   [Usage](#usage)
    -   [Contributing](#contributing)
    -   [License](#license)
    <!--toc:end-->

## Scripts

### JavaProjectManager

**File:** `scripts/JavaProjectManager/JavaProjectManager.zsh`

A versatile command-line utility for Java developers to compile and run Java files. It supports various Java project structures, including IntelliJ IDEA projects, Maven projects, and generic Java files. The script provides an interactive menu for project selection, argument handling, and JVM options. It also manages temporary `.class` files to ensure a clean working environment.

**Features:**

-   Compile and run Java files from different project structures.
-   Interactive menu with fuzzy finder (`fzf`) for file selection.
-   JVM options and argument handling.
-   Clean up temporary `.class` files after execution.
-   Error handling with syntax-highlighted output using `bat`.

### MavenJavaProjectInitializer

**File:** `scripts/MavenJavaProjectInitializer.zsh`

A script to initialize a new Java Maven project with standard directory structures and optional sample Java files. It prompts for project details, creates the `pom.xml` file with appropriate settings, and optionally generates test files.

**Features:**

-   Create standard Maven project directories.
-   Generate `pom.xml` with customizable properties.
-   Option to create sample Java classes with various templates.
-   Build the project using Maven and create a README and `.gitignore`.

### C Compiler

**File:** `scripts/c_compiler.zsh`

A script to compile C programs in the current directory. It lists available `.c` files, prompts the user for the file to compile, and offers options to include debug information. It integrates with LLDB for debugging and provides basic LLDB commands.

**Features:**

-   List and select `.c` files for compilation.
-   Option to compile with debug symbols.
-   Integration with LLDB for debugging.
-   Color-coded output for better readability.

### Get Code Context

**File:** `scripts/get_code_context.sh`

A script to extract code context from specified directories and file types. It recursively reads files and appends their content to an output file. Useful for generating code summaries or documentation.

**Features:**

-   Specify directories and file extensions to include.
-   Ignore certain file types (e.g., images).
-   Interactive mode if no directories or extensions are provided.
-   Output combined code context to a single file.

### HTML to Text Converter

**File:** `scripts/html-to-text.zsh`

A script to fetch website content and convert it to plain text using `lynx`. It prompts for a URL and an output filename, then saves the readable content.

**Features:**

-   Convert web pages to plain text.
-   Simple user prompts for URL and output file.
-   Error handling and validation.

### Image Previewer (imgp)

**File:** `scripts/imgp.sh`

A script to preview images in the terminal. It supports various image formats and uses tools like `fzf`, `bat`, `viu`, and terminal-specific methods for displaying images.

**Features:**

-   Search and select images using `fzf`.
-   Preview images directly in the terminal.
-   Supports iTerm2, Kitty, tmux, and generic terminals.
-   Handles a wide range of image formats.

### Neovim Surround Usage Guide

**File:** `scripts/nvim_surround_usage.sh`

A script that outputs a comprehensive usage guide for the `nvim-surround` plugin, including basic commands, examples, and default surround pairs.

**Features:**

-   Detailed explanations of `nvim-surround` commands.
-   Color-coded output for better readability.
-   Usage examples and quick reference.

### Package Updater

**File:** `scripts/package_updater.zsh`

A script to update various packages and applications on macOS. It handles Homebrew, Conda environments, Oh My Zsh, Node.js, npm packages, and more. It also manages log files and can send email reports.

**Features:**

-   Update Homebrew packages and manage `Brewfile`.
-   Update Conda environments and backup to GitHub.
-   Update tmux plugins and Oh My Zsh.
-   Update Node.js using NVM and npm global packages.
-   Manage log files and send email reports.

### Package Updater for Raspberry Pi

**File:** `scripts/package_updater_rpi.zsh`

Similar to the `package_updater.zsh` script but tailored for Raspberry Pi. It updates apt packages, snap packages, Ruby gems, Cargo packages, and more.

**Features:**

-   Update and clean up apt packages.
-   Update snap packages and Ruby gems.
-   Update Cargo packages and clean registry.
-   Install Node.js LTS and `code-server`.

### SQL URL Generator

**File:** `scripts/sqlurl.sh`

A script to generate a database connection URL by prompting the user for connection details or selecting a `.db` file using `fzf`.

**Features:**

-   Interactive prompts for database credentials.
-   Supports multiple database types (SQLite, MySQL, PostgreSQL, etc.).
-   Generates a connection URL for use in applications.

### Tmux Shortpath

**File:** `scripts/tmux_shortpath.sh`

A script to shorten long file paths for display in tmux status bars or prompts.

**Features:**

-   Shortens paths by replacing intermediate directories with an ellipsis.
-   Useful for keeping status bars clean and readable.

---

## Installation

To use these scripts, you can clone the repository and add the scripts to your `PATH`, or install individual scripts as needed.

```bash
git clone https://github.com/av1155/scripts.git
cd scripts
```

### For the JavaProjectManager, a Homebrew formula is available:

File: [formula/javaprojectmanager.rb](./formula/javaprojectmanager.rb)

You can install it using:

```bash
brew tap av1155/scripts https://github.com/av1155/scripts.git
brew install javaprojectmanager
```

To uninstall:

```bash
brew uninstall javaprojectmanager
brew untap av1155/scripts
```

## Usage

Most scripts include usage instructions within the code or via help options. For example:

JavaProjectManager:

```bash
jcr --help
```

Ensure you have the necessary dependencies installed as specified in each script.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

## License

This project is licensed under the MIT License.
