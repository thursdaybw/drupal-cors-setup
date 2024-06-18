#!/bin/bash
# This script sets up the Angular front-end environment

# Ensure DDEV is installed
if ! command -v ddev &> /dev/null; then
    echo "DDEV is not installed. Please install DDEV and try again."
    exit 1
fi

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
ddev config --project-type nodejs --project-name $FRONTEND_ENV --docroot .
ddev start

# Install Angular CLI globally within the DDEV container
ddev exec "npm install -g @angular/cli"

# Create a new Angular project
ddev exec "ng new drupal-headless --directory . --skip-install"
ddev exec "npm install"

# Add required Angular dependencies
ddev exec "npm install @angular/common @angular/core @angular/platform-browser @angular/router @angular/forms"

# Copy Angular templates to the project directory
cp -r "$SCRIPT_DIR/templates/*" "$FRONTEND_PROJECT_DIR/src/app/"

# Print completion message
echo "Angular setup completed successfully."

