# README for JavaProjectManager Script

## Overview

JavaProjectManager is a versatile command-line utility designed to help Java developers compile and execute Java files effortlessly. Tailored to work with various Java project structures, including IntelliJ IDEA projects, Maven projects, and Generic Java projects, this script offers an interactive menu for a seamless development experience outside of an IDE environment.

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

## Features

-   **Interactive Menu**: Easily select the project structure or specific actions to perform, enhancing user interaction.
-   **Multiple Project Support**: Supports IntelliJ IDEA, Maven, and generic Java projects.
-   **Argument Handling**: Facilitates passing arguments to the Java program being executed, directly from the command line.
-   **Clean Environment**: Manages and cleans up temporary `.class` files to maintain a clutter-free workspace.
-   **Error Handling**: Robust error handling mechanisms are in place, providing clear and understandable compilation and execution error messages.
-   **Maven Integration**: Allows for the execution of Maven commands, including `mvn test`, directly within the script.

## Dependencies

-   `fzf`: For interactive file selection.
-   `bat`: For enhanced file content display.
-   `javac`: Java compiler for compiling Java files.
-   `java`: Java runtime for executing compiled Java programs.
-   `mvn`: Maven command-line tool (for Maven project support).

## Installation

Ensure the required dependencies (fzf, bat, javac, java, and mvn for Maven projects) are installed on your system. You can typically install these through your package manager on Linux or Homebrew on macOS.

## Usage

```bash
jcr [OPTIONS]
```

### Options

-   `-h`, `--help`: Display the help message and exit.
-   `-v`, `--version`: Display version information and exit.

### Interactive Menu

1.  **IntelliJ IDEA Project**: Select this option to compile and run files from an IntelliJ IDEA project.
2.  **Maven Project**: Choose this to compile and run files from a Maven project. This includes support for running Maven tests (`mvn test`).
3.  **Generic Java Project**: Choose this for generic Java projects not tied to any specific IDE or structure.
4.  **Re-run Last Executed File**: Quickly re-execute the last file without navigating through the menu.

### Argument Handling

When prompted, you can provide runtime arguments for your Java program, separated by spaces.

## Cleanup

The script includes a cleanup function triggered upon script interruption, ensuring that all generated `.class` files are deleted, keeping your workspace clean.

## Contributing

Contributions to enhance the script, add features, or improve its usability are welcome. Feel free to fork the repository and submit pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
