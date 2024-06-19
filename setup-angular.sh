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
ddev config --project-type php --project-name $FRONTEND_ENV --docroot public/browser

# Add NG_CLI_ANALYTICS to web_environment in .ddev/config.yaml
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

# Create a temporary index.html for testing
mkdir -p public/browser
echo '<h1>Temporary Index for Testing</h1>' > public/browser/index.html

# Check if the URL is accessible
DDEV_URL="https://drupal-headless-frontend.ddev.site"
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' $DDEV_URL)
if [ "$HTTP_CODE" -ne 200 ]; then
    echo "Error: curl check failed with HTTP code $HTTP_CODE"
    exit 1
fi

# Clean up the temporary index.html
rm public/browser/index.html

# Configure Node.js version in DDEV
ddev config --nodejs-version="14"

# Install Angular CLI globally within the DDEV container
ddev exec 'npm install -g @angular/cli'

# Create a new Angular project
ddev exec 'ng new drupal-headless --directory . --skip-install --style=css --routing=false --skip-git --strict=false --no-ssr'

ddev exec 'npm install'

# Generate a new component
ddev exec 'ng generate component my-component'

# Add the new component to the app component
ddev exec 'sed -i "1 i\\import { MyComponentComponent } from '\''./my-component/my-component.component'\'';" src/app/app.component.ts'
ddev exec 'sed -i "s/imports: \[\]/imports: \[MyComponentComponent\]/" src/app/app.component.ts'

# Modify the component to display "Hello World"
ddev exec 'echo "<h1>Hello World from MyComponent</h1>" > src/app/my-component/my-component.component.html'

# Include the new component in the app component HTML
ddev exec 'echo "<app-my-component></app-my-component>" >> src/app/app.component.html'

# Build the Angular project
ddev exec 'ng build --output-path=public'

# Check for nested browser directory
if [ -d public/browser/browser ]; then
    echo "Error: Nested directory 'public/browser/browser' found"
    exit 1
fi

# Check contents of public/browser directory
echo "Checking contents of public/browser directory after build:"
ddev exec 'ls -al public/browser'

# Check permissions of public/browser directory
ddev exec 'find public/browser -type f -exec stat -c "%a %n" {} \;'

# Check if the URL is accessible after the build
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' $DDEV_URL)
if [ "$HTTP_CODE" -ne 200 ]; then
    echo "Error: curl check failed with HTTP code $HTTP_CODE after build"
    exit 1
fi

# Print completion message
echo "Angular setup completed successfully."

