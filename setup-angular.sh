#!/bin/bash
# This script sets up the Angular front-end environment

# Check if the script is being called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Default script directory
    # Get the full path to the script, regardless of where it is being called from
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

    # Source the common configuration file
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/common-config.sh"
fi

# Function to check the last command status and exit if it failed
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed"
        exit 1
    fi
}

# Function to check if a file or directory exists
check_exists() {
    if [ ! -e "$1" ]; then
        echo "Error: $1 does not exist"
        exit 1
    fi
}

# Function to check if a file or directory does not exist
check_not_exists() {
    if [ -e "$1" ]; then
        echo "Error: $1 still exists"
        exit 1
    fi
}

# Function to check file permissions
check_permissions() {
    if [ "$(stat -c "%a" "$1")" != "$2" ]; then
        echo "Error: $1 does not have the correct permissions"
        exit 1
    fi
}

# Set up directories and project names
FRONTEND_ENV="${PROJECT_NAME}-frontend"

# Set up directory variables
FRONTEND_PROJECT_DIR="$WORKSPACE_DIR/$FRONTEND_ENV"

# Stop and delete frontend project if it exists
if ddev describe $FRONTEND_ENV &>/dev/null; then
  ddev stop $FRONTEND_ENV
  ddev delete $FRONTEND_ENV --omit-snapshot -y
  rm -rf "$FRONTEND_PROJECT_DIR"
fi

# Check if project directory was deleted
check_not_exists "$FRONTEND_PROJECT_DIR"

# Set up the frontend DDEV environment with Node.js and Angular
echo "Creating the $FRONTEND_ENV DDEV environment..."
mkdir -p "$FRONTEND_PROJECT_DIR"
check_exists "$FRONTEND_PROJECT_DIR"

cd "$FRONTEND_PROJECT_DIR" || exit

# Initialize DDEV project for Node.js
ddev config --project-type php --project-name $FRONTEND_ENV --docroot public/browser
check_command 'ddev config'

ddev start
check_command 'ddev start'

# Create a temporary index.html for testing
mkdir -p public/browser
echo '<h1>Temporary Index for Testing</h1>' > public/browser/index.html
check_exists public/browser/index.html

# Check if the URL is accessible
DDEV_URL="https://drupal-headless-frontend.ddev.site"
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' $DDEV_URL)
if [ "$HTTP_CODE" -ne 200 ]; then
    echo "Error: curl check failed with HTTP code $HTTP_CODE"
    exit 1
fi
check_command 'curl check'

# Clean up the temporary index.html
rm public/browser/index.html
check_not_exists public/browser/index.html

# Configure Node.js version in DDEV
ddev config --nodejs-version="14"
check_command 'ddev config --nodejs-version'

# Install Angular CLI globally within the DDEV container
ddev exec 'npm install -g @angular/cli'
check_command 'npm install -g @angular/cli'

# Create a new Angular project
ddev exec 'export NG_CLI_ANALYTICS=false && ng new drupal-headless --directory . --skip-install --style=css --routing=false --skip-git --strict=false --no-ssr --skip-install'
check_command 'ng new drupal-headless'

ddev exec 'npm install'
check_command 'npm install'

# Generate a new module
ddev exec 'export NG_CLI_ANALYTICS=false && ng generate module app --routing'
check_command 'ng generate module app'

# Generate a new component
ddev exec 'ng generate component app'
check_command 'ng generate component app'

# Modify the component to display "Hello World"
ddev exec 'echo "<h1>Hello World from AppComponent</h1>" > src/app/app.component.html'
check_command 'Modify AppComponent'

# Build the Angular project
ddev exec 'export NG_CLI_ANALYTICS=false && ng build --output-path=public/browser'
check_command 'ng build'

# Check for nested browser directory
if [ -d public/browser/browser ]; then
    echo "Error: Nested directory 'public/browser/browser' found"
    exit 1
fi

# Check contents of public/browser directory
echo "Checking contents of public/browser directory after build:"
ddev exec 'ls -al public/browser'
check_command 'ls public/browser'

# Check permissions of public/browser directory
ddev exec 'find public/browser -type f -exec stat -c "%a %n" {} \;'
check_command 'check permissions'

# Check if the URL is accessible after the build
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' $DDEV_URL)
if [ "$HTTP_CODE" -ne 200 ]; then
    echo "Error: curl check failed with HTTP code $HTTP_CODE after build"
    exit 1
fi
check_command 'curl check after build'

# Print completion message
echo "Angular setup completed successfully."

