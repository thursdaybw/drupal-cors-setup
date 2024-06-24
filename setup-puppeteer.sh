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
if ddev describe $PUPPETEER_ENV &>/dev/null; then
  ddev stop $PUPPETEER_ENV
  ddev delete $PUPPETEER_ENV --omit-snapshot -y
  rm -rf "$PUPPETEER_PROJECT_DIR"
fi


# Create the frontend DDEV environment
echo "Creating the $PUPPETEER_ENV DDEV environment..."
mkdir -p "$PUPPETEER_PROJECT_DIR"
cd "$PUPPETEER_PROJECT_DIR" || exit

# Initialize DDEV project
ddev config --project-type php --project-name $PUPPETEER_ENV --docroot .

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

ddev get thursdaybw/vnc

cp "$SCRIPT_DIR/docker-compose.backend-alias.yml" .ddev/

# Configure Node.js version in DDEV
ddev config --nodejs-version="18"

# Copy the Puppeteer script to the project directory
cp "$SCRIPT_DIR/puppeteer-script.js" "$PUPPETEER_PROJECT_DIR/"

ddev start

ddev exec "ng install puppeteer"

$VNC_DIR="$PUPPETEER_PROJECT_DIR/.ddev/.vnc/"
mkdir -p $VNC_DIR 
echo "password" | vncpasswd -f > "${VNC_DIR}/passwd
vncviewer -passwd "$VNC_DIR/passwd" localhost:5901

ddec exec "node puppeteer.js"
