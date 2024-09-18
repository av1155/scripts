# JavaProjectManager Script

<!--toc:start-->

-   [JavaProjectManager Script](#javaprojectmanager-script)
    -   [Overview](#overview)
    -   [Homebrew Formula](#homebrew-formula)
    -   [Features](#features)
    -   [Dependencies](#dependencies)
    -   [Installation](#installation)
    -   [Usage](#usage)
        -   [Options](#options)
        -   [Interactive Menu](#interactive-menu)
        -   [JVM Options](#jvm-options)
        -   [Argument Handling](#argument-handling)
    -   [Cleanup](#cleanup)
    -   [Contributing](#contributing)
    -   [License](#license)
    <!--toc:end-->

## Overview

JavaProjectManager is a versatile command-line utility designed to help Java developers compile and execute Java files effortlessly. It supports various Java project structures, including IntelliJ IDEA projects, Maven projects, and generic Java projects. With an interactive menu, it offers a seamless development experience outside of an IDE.

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

-   **Interactive Menu**: Easily select project structure or actions, enhancing user interaction.
-   **Multiple Project Support**: Supports IntelliJ IDEA, Maven, and generic Java projects.
-   **Argument Handling**: Pass arguments to the Java program directly from the command line.
-   **Custom JVM Options**: Specify custom JVM options (e.g., `-Xmx1g`) before running your Java program.
-   **Clean Environment**: Manages and removes temporary `.class` files, keeping the workspace clean.
-   **Error Handling**: Provides clear and understandable error messages for compilation and execution failures.
-   **Maven Integration**: Execute Maven commands such as `mvn test` within the script.

## Dependencies

Ensure the following dependencies are installed:

-   `fzf`: For interactive file selection.
-   `bat`: For enhanced file content display.
-   `javac`: Java compiler for compiling Java files.
-   `java`: Java runtime for executing compiled Java programs.
-   `mvn`: Maven command-line tool (for Maven projects).

## Installation

You can install the required dependencies via your package manager (Linux) or Homebrew (macOS). Example:

```bash
brew install fzf bat java maven
```

## Usage

```bash
jcr [OPTIONS]
```

### Options

-   `-h`, `--help`: Display the help message and exit.
-   `-v`, `--version`: Display version information and exit.

### Interactive Menu

1. IntelliJ IDEA Project: Compile and run files from an IntelliJ IDEA project.
2. Maven Project: Compile and run files from a Maven project, or run mvn test.
3. Generic Java Project: Compile and run files from a generic Java project.
4. Re-run Last Executed File: Quickly re-execute the last file without navigating the menu.

### JVM Options

When compiling and running a Java file, the script will now prompt you to enter any JVM options (e.g., `-Xmx1g` to allocate 1GB of memory). These options allow you to control the behavior of the JVM, including memory allocation, garbage collection, and more. Some common JVM options include:

-   `-Xmx<size>`: Sets the maximum heap size (e.g., `-Xmx2g` for 2GB).
-   `-Xms<size>`: Sets the initial heap size (e.g., `-Xms512m` for 512MB).
-   `-XX:+UseG1GC`: Enables the G1 garbage collector.

You can enter the desired options or press Enter to skip this step.

### Argument Handling

When prompted, you can provide runtime arguments for your Java program, separated by spaces.

## Cleanup

The script includes a cleanup function triggered upon script interruption, ensuring that all generated `.class` files are deleted, keeping your workspace clean.

## Contributing

Contributions to enhance the script, add features, or improve its usability are welcome. Feel free to fork the repository and submit pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
