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

# Create the frontend DDEV environment
echo "Creating the $FRONTEND_ENV DDEV environment..."
mkdir -p "$FRONTEND_PROJECT_DIR"
cd "$FRONTEND_PROJECT_DIR" || exit


# Initialize DDEV project
ddev config --project-type php --project-name $FRONTEND_ENV --docroot .

cp "$SCRIPT_DIR/vnc/"* "$FRONTEND_PROJECT_DIR/.ddev/web-build/"

ddev start

cp "$SCRIPT_DIR/docker-compose.backend-alias.yml" .ddev/

# Configure Node.js version in DDEV
ddev config --nodejs-version="18"

# Add required packages for puppeteer to webimage_extra_packages in .ddev/config.yaml
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

ddev start

# Install puppeteer CLI globally within the DDEV container
ddev exec 'npm install puppeteer'
ddev exec 'npm install'

# Create the index.html file in the frontend project
INDEX_FILE="$FRONTEND_PROJECT_DIR/index.html"

# Copy the HTML template to the working directory and replace placeholders
cp "$SCRIPT_DIR/index_template.html" "$INDEX_FILE"
sed -i "s#%%CORS_ENV%%#${CORS_ENV}#g" "$INDEX_FILE"
echo "index.html has been created in the $FRONTEND_PROJECT_DIR/ project at $INDEX_FILE"

# Run the puppeteer test to ensure the functionality of the app.
cp "$SCRIPT_DIR/puppeteer-script.js" "$FRONTEND_PROJECT_DIR/"
ddev exec 'node puppeteer-script.js' || { echo "Puppeteer test failed. Exiting."; exit 1; }
