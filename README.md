# My Bash Scripts Repository

## Introduction

This repository contains a collection of Bash scripts that I've created for
various tasks. These scripts are designed to automate tasks, enhance
productivity, and make life easier.

## Homebrew Formula

To install `JavaProjectManager.zsh` using Homebrew:

1.  Tap the repository:

    ```bash
    brew tap av1155/scripts https://github.com/av1155/scripts
    ```

2.  Install the script:

    ```bash
    brew install javaprojectmanager
    ```

To uninstall:

1.  Remove the script:

    ```bash
    brew uninstall javaprojectmanager
    ```

2.  Untap the repository (if not needed anymore):

    ```bash
    brew untap av1155/scripts
    ```

## Scripts

Here's a brief overview of the scripts included in this repository:

### [JavaProjectManager.zsh](scripts/JavaProjectManager/JavaProjectManager.zsh)

This dynamic ZSH script is engineered to streamline the compilation and execution of Java files. It's adept at accommodating various project structures like IntelliJ IDEA and generic Java files, seamlessly blending into these setups. Notable features encompass:

-   Comprehensive error handling and debugging with syntax-highlighted compilation errors for efficient issue identification and resolution during compilation and execution phases.
-   Interactive file selection facilitated by `fzf`, augmented with a file preview functionality via `bat`.
-   Proficiency in managing project-specific structures and tidying up `.class` files after execution.
-   Memorization of the last executed file's path to simplify subsequent recompilation and reruns.
-   Support for inputting arguments for Java programs, enhancing flexibility.
-   Enhanced output with color-coding for improved clarity and user interaction.

### [package_updater.zsh](scripts/package_updater.zsh)

A robust script for updating Homebrew, Conda environments, Oh My Zsh, Mac App Store applications, Node.js, npm packages, and AstroNvim plugins. Designed for automation and ease of use, especially in non-interactive environments like cron jobs. Features include:

-   Initialization and management of key software environments and paths.
-   Comprehensive update mechanisms for a variety of software tools and utilities.
-   Detailed status output with color-coded text for clear and immediate feedback.
-   Optional logging and reporting features to keep track of script activities and outcomes.
-   Conditional logic to handle various installation states and user interaction scenarios.

### [MavenJavaProjectInitializer.zsh](scripts/MavenJavaProjectInitializer.zsh)

This script is a powerful tool for automating the creation of Java projects with Maven. It offers a range of features to streamline project setup and ensure proper structure. Key functionalities include:

-   Validation of project and class names, ensuring adherence to naming conventions and avoidance of Java reserved words.
-   Automatic creation of standard Maven project directories and essential files like `pom.xml` and `README.md`.
-   Customizable Java class file generation with template options such as Basic, With Constructor, Singleton, and With Getters/Setters.
-   Option to create JUnit test files with a basic test template.
-   Integration of Maven for project building, including checks for Java and Maven installations.
-   Creation of a `.gitignore` file tailored for Java and Maven projects.
-   Handling of error scenarios with a cleanup mechanism to remove partially created project files and directories.

### [imgp.sh](scripts/imgp.sh)

This script is a flexible tool for viewing images directly in various terminal environments. It is designed to work with iTerm2, Kitty, tmux, and other terminals via the viu image viewer. Key features include:

-   Ability to search and select image files within a specified directory depth, using the powerful fzf tool for file selection.
-   Support for a wide range of image formats, including jpg, jpeg, png, gif, webp, tiff, bmp, heif, avif, and many more.
-   Customizable depth setting for file search, allowing users to define how deep the script searches for image files.
-   Integration with terminal-specific image viewers like iTerm2's imgcat, Kitty's icat, and viu, ensuring optimal display in different environments.
-   Option to specify a filename directly for quick image viewing.
-   Automated terminal detection to utilize the best available method for displaying images based on the user's current terminal setup.

### [sqlurl.sh](scripts/sqlurl.sh)

This script is an essential utility for database management, providing a streamlined approach to connect to various database systems. It is specifically tailored for users who frequently interact with databases in their development workflow. Key functionalities include:

-   Interactive selection of `.db` files in the current directory using the fzf tool.
-   Support for multiple database management tools including SQLite, MySQL, PostgreSQL, MSSQL, Oracle, and MongoDB.
-   User-friendly prompts for entering database connection details like username, password, hostname, port, and database name.
-   Automatic construction of database connection URLs based on user input, catering to different database systems.
-   Color-coded output for better readability and user experience.
-   Validation of user input to ensure the correct selection of database tools and connection parameters.

### nvim_surround_usage.sh[JavaProjectManager.zsh](scripts/JavaProjectManager/JavaProjectManager.zsh)

This script serves as a quick reference guide for the Vim Surround plugin in Neovim. It outlines the core operations of adding, deleting, and changing text surroundings, which are essential for efficient code editing. Key highlights include:

-   Keymaps for adding (`ys`), deleting (`ds`), and changing (`cs`) text surroundings.
-   Practical examples demonstrating how to apply these keymaps in various editing scenarios.
-   Coverage of common use cases like surrounding words, making strings, deleting tags, and changing quotes.
-   Instructions for working with different types of text elements, including parentheses, brackets, quotes, and HTML tags.
-   A simple, easy-to-read format that allows users to quickly reference and apply these keymaps in their editing workflow.

## Installation

To use these scripts, clone the repository to your local machine:

```bash
git clone https://github.com/av1155/scripts.git
```

Then navigate to the scripts directory:

```bash
cd scripts
```

You can run any script by typing `./scriptname.sh`.

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for
details.
