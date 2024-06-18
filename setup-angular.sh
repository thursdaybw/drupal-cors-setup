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

# Set up the frontend DDEV environment with Node.js and Angular
echo "Creating the $FRONTEND_ENV DDEV environment..."
mkdir -p "$FRONTEND_PROJECT_DIR"
cd "$FRONTEND_PROJECT_DIR" || exit

# Initialize DDEV project for Node.js
ddev config --project-type php --project-name $FRONTEND_ENV --docroot .
ddev start

# Configure Node.js version in DDEV
ddev config --nodejs-version="14"

# Install Angular CLI globally within the DDEV container
ddev exec "npm install -g @angular/cli"

# Create a new Angular project
ddev exec "export NG_CLI_ANALYTICS=false && ng new drupal-headless --directory . --skip-install --style=css --routing=false --skip-git --strict=false --no-ssr --skip-install"

ddev exec "npm install"

# Add required Angular dependencies
ddev exec "npm install @angular/common @angular/core @angular/platform-browser @angular/router @angular/forms"

# Check if the template directory exists and copy templates to the project directory
if [ -d "$SCRIPT_DIR/templates" ]; then
  cp -r "$SCRIPT_DIR/templates/"* "$FRONTEND_PROJECT_DIR/src/app/"
else
  echo "Template directory not found: $SCRIPT_DIR/templates"
  exit 1
fi


# Print completion message
echo "Angular setup completed successfully."

