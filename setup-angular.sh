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
ddev config --project-type php --project-name $FRONTEND_ENV --docroot public/browser

if grep -q "^web_environment:" .ddev/config.yaml; then
    if grep -q "^web_environment: \[\]" .ddev/config.yaml; then
        sed -i '/^web_environment: \[\]/s/web_environment: \[\]/web_environment:\n  - NG_CLI_ANALYTICS=false/' .ddev/config.yaml
    elif ! grep -q "^  - NG_CLI_ANALYTICS=false" .ddev/config.yaml; then
        sed -i '/^web_environment:/a\  - NG_CLI_ANALYTICS=false' .ddev/config.yaml
    fi
else
    echo -e "\nweb_environment:\n  - NG_CLI_ANALYTICS=false" >> .ddev/config.yaml
fi

ddev start

# Install Angular CLI globally within the DDEV container
ddev exec "npm install -g @angular/cli"

# Create a new Angular project
ddev exec 'ng new drupal-headless --standalone --directory . --skip-install --style=css --routing=false --skip-git --strict=false --no-ssr'
ddev exec "npm install"

# Add required Angular dependencies
#ddev exec "npm install @angular/common @angular/core @angular/platform-browser @angular/router @angular/forms"

ddev exec "ng build --output-path public"

# Copy Angular templates to the project directory
cp -r "$SCRIPT_DIR/templates/*" "$FRONTEND_PROJECT_DIR/src/app/"


# Print completion message
echo "Angular setup completed successfully."

ddev describe
