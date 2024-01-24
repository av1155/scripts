#!/bin/zsh

# JavaProject Generator

# Define some color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Java reserved words
JAVA_RESERVED_WORDS=("abstract" "assert" "boolean" "break" "byte" "case" "catch" "char" "class" "const" "continue" "default" "do" "double" "else" "enum" "extends" "final" "finally" "float" "for" "goto" "if" "implements" "import" "instanceof" "int" "interface" "long" "native" "new" "package" "private" "protected" "public" "return" "short" "static" "strictfp" "super" "switch" "synchronized" "this" "throw" "throws" "transient" "try" "void" "volatile" "while")


# Function to validate the project name
validate_project_name() {
    if ! [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}Error: Invalid project name. Please use only alphanumeric characters, hyphens, or underscores.${NC}"
        return 1
    fi
}


# Function to create the project directory
create_project_directory() {
    mkdir -p "$1" || { echo -e "${RED}Error: Could not create project directory.${NC}"; return 1; }
    cd "$1" || { echo -e "${RED}Error: Could not change to project directory.${NC}"; return 1; }
}


# Function to create the pom.xml file
create_pom_file() {
    touch pom.xml || { echo -e "${RED}Error: Could not create pom.xml.${NC}"; cleanup; return 1; }
}


# Function to validate the class name
validate_class_name() {
    if ! [[ "$1" =~ ^[a-zA-Z_$][a-zA-Z\d_$]*$ ]]; then
        echo -e "${RED}Error: Invalid class name. Please use a valid identifier.${NC}"
        cleanup "$project_name"
        return 1
    fi

    # Check if class name is a Java reserved word
    for word in "${JAVA_RESERVED_WORDS[@]}"; do
        if [[ "$1" == "$word" ]]; then
            echo -e "${RED}Error: The class name cannot be a reserved word in Java.${NC}"
            cleanup "$project_name"
            return 1
        fi
    done
}



# Function to create a sample Java file based on a template
create_java_file() {
    echo "" # Add a newline
    echo -e "${BLUE}Do you want to create a Java file? (y/n, default: n):${NC}"
    echo -n "> "
    read -r create_java_choice

    echo ""

    if [[ "$create_java_choice" == "y" ]]; then
        # Ask for the class name
        echo -n "${BLUE}Enter the class name:${NC} "
        read class_name

        # Validate class name
        validate_class_name "$class_name" || return 1

        echo -e "${BLUE}Choose a template:${NC}"
        echo "1) Basic"
        echo "2) With Constructor"
        echo "3) Singleton"
        echo "4) With Getters/Setters"
        echo -n "> "
        read -r template_choice

        echo ""

        case "$template_choice" in
            1)
                cat <<EOF > src/main/java/${class_name}.java
public class ${class_name} {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
}
EOF
                ;;
            2)
                cat <<EOF > src/main/java/${class_name}.java
public class ${class_name} {
    public ${class_name}() {
        // constructor code here
    }
}
EOF
                ;;
            3)
                cat <<EOF > src/main/java/${class_name}.java
public class ${class_name} {
    private static ${class_name} instance;
    private ${class_name}() {
        // private constructor
    }
    public static ${class_name} getInstance() {
        if (instance == null) {
            instance = new ${class_name}();
        }
        return instance;
    }
}
EOF
                ;;
            4)
                cat <<EOF > src/main/java/${class_name}.java
public class ${class_name} {
    private String field;
    public String getField() {
        return field;
    }
    public void setField(String field) {
        this.field = field;
    }
}
EOF
                ;;
            *)
                echo -e "${RED}Error: Invalid template choice.${NC}"
                cleanup "$project_name"
                return 1
                ;;
        esac
    else
        echo -e "${GREEN}No Java file created.${NC}"
    fi
}




# Function to create a sample Java test file based on a template
create_java_test_file() {
    cat <<EOF > src/test/java/${class_name}Test.java
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class ${class_name}Test {

    @Test
    void test() {
        ${class_name} instance = new ${class_name}();
        // TODO: Implement your test here
        // Example: assertEquals(expectedValue, instance.methodToTest());
    }
}
EOF
}


# Function to check for Maven and build the project
build_project() {
    if ! command -v java &> /dev/null; then
        echo -e "${RED}Error: Java is not installed.${NC}"
        cleanup "$project_name"
        return 1
    fi

    if ! command -v mvn &> /dev/null; then
        echo -e "${RED}Error: Maven is not installed.${NC}"
        cleanup "$project_name"
        return 1
    fi

    echo "" # Add a newline

    echo -e "${GREEN}Building project with Maven...${NC}"
    mvn clean install | tee build.log
    if [ $pipestatus[1] -ne 0 ]; then
        echo -e "${RED}Error: Maven build failed. Check build.log for details.${NC}"
        cleanup "$project_name"
        return 1
    fi
}


# Function to create a README file
create_readme_file() {
    cat <<EOF > README.md
# $1

This is a simple Java project generated by a script.

## Build

To build the project, run the following command:

\`\`\`
mvn clean install
\`\`\`

## Run

To run the main class, use the following command:

\`\`\`
java -cp target/$1-0.1-SNAPSHOT.jar com.example.$2
\`\`\`
EOF
}


# Function to create a .gitignore file
create_gitignore_file() {
    cat <<EOF > .gitignore
# Ignore Maven build output directory
target/

# Ignore IDE files
.idea/
*.iml

# Ignore log files
*.log
EOF
}

# Function to get Java version
get_java_version() {
    local version
    version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk -F '.' '{print $1}')
    if [[ -z "$version" ]]; then
        echo "Error: Could not determine Java version."
        return 1
    fi
    echo "$version"
}


# Main function to create a Java project
javaproject() {
    # Check if a project name is provided
    if [ -z "$1" ]; then
        echo -e "${RED}Usage: javaproject <project_name>${NC}"
        return 1
    fi

    # Project name provided as the first command-line argument
    project_name="$1"

    # Validate project name
    validate_project_name "$project_name" || return 1

    # Confirm project creation
    echo -n "${BLUE}Do you want to create the project${NC} '$project_name'${BLUE}? (y/n):${NC} "
    read confirm
    [[ $confirm != "y" ]] && { echo "${RED}Project creation aborted.${NC}"; return 0; }

    # Create directory and navigate into it
    create_project_directory "$project_name" || return 1

    # Logging
    echo -e "${GREEN}Creating project directory:${NC} $project_name"
    echo -e "${GREEN}Creating standard Maven directories...${NC}"

    # Create standard Maven directories
    mkdir -p src/main/java
    mkdir -p src/test/java

    # Create pom.xml file
    create_pom_file || return 1

    # Get Java version
    local java_version
    java_version=$(get_java_version) || { echo -e "${RED}Error: Could not determine Java version.${NC}"; return 1; }

    # Add content to pom.xml
    cat <<EOF > pom.xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">

    <modelVersion>4.0.0</modelVersion>
    <groupId>com.github.av1155</groupId>
    <artifactId>$project_name</artifactId>
    <packaging>jar</packaging>
    <version>0.1-SNAPSHOT</version>


    <properties>
        <maven.compiler.source>$java_version</maven.compiler.source>
        <maven.compiler.target>$java_version</maven.compiler.target>
    </properties>


    <build>
        <sourceDirectory>src/main/java</sourceDirectory>
        <outputDirectory>target/classes</outputDirectory>
        <testSourceDirectory>src/test/java</testSourceDirectory>
        <testOutputDirectory>target/test-classes</testOutputDirectory>
    </build>

    <dependencies>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter</artifactId>
            <version>5.10.1</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

</project>
EOF

    # Create a sample Java file
    create_java_file || return 1

    # Ask if the user wants to create a test file
    echo -e "${BLUE}Do you want to create a test file? (y/n, default: n):${NC}"
    echo -n "> "
    read -r create_test_file

    if [[ "$create_test_file" == "y" ]]; then
        # Create a sample Java test file
        create_java_test_file || return 1
    fi

    # Create a README file
    create_readme_file "$project_name" "$class_name"

    # Create a .gitignore file
    create_gitignore_file

    # Check for Maven and build the project
    build_project || return 1

    echo "" # Add a newline
    echo -e "${GREEN}Project${NC} '$project_name' ${GREEN}created successfully!${NC}"
}

cleanup() {
    echo -e "${RED}Cleaning up created files and directories...${NC}"
    cd ..
    rm -rf "$1"
}
