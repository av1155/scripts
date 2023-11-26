# My Bash Scripts Repository

## Introduction

This repository contains a collection of Bash scripts that I've created for
various tasks. These scripts are designed to automate tasks, enhance
productivity, and make life easier.

## Scripts

Here's a brief overview of the scripts included in this repository:

1. `JavaCompiler.zsh`: A dynamic ZSH script designed to simplify the compilation
   and execution of Java files. Supporting different project structures like
   IntelliJ IDEA and JavaProject (`JavaProject.zsh`), the script utilizes the
   interactive file selection capabilities of fzf, allowing users to
   effortlessly choose Java files. The file preview functionality, powered by
   bat, enhances the selection process by providing a visually appealing and
   informative display. This combination of fzf and bat not only makes file
   selection easy but also adds a touch of elegance to the user experience. The
   script seamlessly handles the compilation and execution of Java files, making
   it a convenient and visually pleasing tool for Java developers.
2. `JavaProject.zsh`: A comprehensive ZSH script designed to expedite the
   creation of Java projects. This script automates the setup of project
   directories, generates standard Maven structures, and facilitates the
   creation of Java classes with customizable templates. It includes optional
   features such as generating JUnit test files, creating a .gitignore file to
   exclude unnecessary files from version control, and constructing essential
   project files like pom.xml and README.md. The script ensures project
   integrity through validation of project and class names, avoidance of Java
   reserved words, and provides a cleanup mechanism in case of errors. With
   interactive prompts and versatile options, it offers a user-friendly
   experience tailored to diverse project needs.

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

This project is licensed under the MIT License - see the `LICENSE.md` file for
details.
