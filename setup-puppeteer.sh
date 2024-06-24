VNC_DIR="$SCRIPT_DIR/.vnc"
LOG_FILE="$SCRIPT_DIR/vncviewer.log"

# Launch vncviewer in the background using the password file and redirect output to a log file
vncviewer -passwd "${VNC_DIR}/passwd" localhost:5901 > "$LOG_FILE" 2>&1 &
VNC_PID=$!

# Run the Puppeteer test to ensure the functionality of the app.
cp "$SCRIPT_DIR/puppeteer-script.js" "$FRONTEND_PROJECT_DIR/"
ddev exec 'node puppeteer-script.js'

# Capture the exit status of the Puppeteer script
PUPPETEER_EXIT_STATUS=$?

# Kill the vncviewer process
kill $VNC_PID

# Check the Puppeteer exit status and handle failure
if [ $PUPPETEER_EXIT_STATUS -ne 0 ]; then
  echo "Puppeteer test failed. Exiting."
  exit 1
fi


#!/bin/bash

# Define variables
SCRIPT_DIR="/home/bevan/workspace/cors-setup"
FRONTEND_PROJECT_DIR="/home/bevan/workspace/cors-setup/drupal-headless-frontend"

# Copy the Puppeteer script to the project directory
cp "$SCRIPT_DIR/puppeteer-script.js" "$FRONTEND_PROJECT_DIR/"

# Add required packages to webimage_extra_packages in .ddev/config.yaml
PACKAGES=(
    "libnss3"
    "libatk1.0-0"
    "libatk-bridge2.0-0"
    "libcups2"
    "libgbm1"
    "libxkbcommon0"
    "libpango-1.0-0"
    "libxcomposite1"
    "libxcursor1"
    "libxdamage1"
    "libxi6"
    "libxtst6"
    "libxrandr2"
    "libasound2"
)

for package in "${PACKAGES[@]}"; do
    if grep -q "^webimage_extra_packages:" .ddev/config.yaml; then
        if grep -q "^webimage_extra_packages: \[\]" .ddev/config.yaml; then
            sed -i "/^webimage_extra_packages: \[\]/s/webimage_extra_packages: \[\]/webimage_extra_packages:\n  - $package/" .ddev/config.yaml
        elif ! grep -q "^  - $package" .ddev/config.yaml; then
            sed -i "/^webimage_extra_packages:/a\  - $package" .ddev/config.yaml
        fi
    else
        echo -e "\nwebimage_extra_packages:\n  - $package" >> .ddev/config.yaml
    fi
done

# Restart DDEV to apply changes
ddev restart

# Install Puppeteer in the project directory
ddev exec 'cd /var/www/html && npm install puppeteer'

# Run the Puppeteer script and handle errors
ddev exec 'node puppeteer-script.js' || { echo "Puppeteer test failed. Exiting."; exit 1; }

