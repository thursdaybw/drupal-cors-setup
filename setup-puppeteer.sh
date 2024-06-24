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

cp $SCRIPT_DIR/puppeteer/config.puppeteer.yml $PUPPETEER_PROJECT_DIR/.ddev/ 
cp $SCRIPT_DIR/puppeteer/docker-compose.frontend-alias.yml $PUPPETEER_PROJECT_DIR/.ddev/ 

ddev get thursdaybw/ddev-vnc

cp "$SCRIPT_DIR/docker-compose.backend-alias.yml" .ddev/

# Configure Node.js version in DDEV
ddev config --nodejs-version="18"

# Copy the Puppeteer script to the project directory
cp "$SCRIPT_DIR/puppeteer/puppeteer.js" "$PUPPETEER_PROJECT_DIR/"

ddev start

ddev exec "npm install puppeteer"

VNC_DIR="$PUPPETEER_PROJECT_DIR/.ddev/.vnc/"
VNCVIEWER_LOG_FILE="$PUPPETEER_PROJECT_DIR/.ddev/.vnc/vncviewer.log"

mkdir -p $VNC_DIR 
echo "password" | vncpasswd -f > "${VNC_DIR}/passwd"
vncviewer -passwd "${VNC_DIR}/passwd" localhost:5901 > "$VNCVIEWER_LOG_FILE" 2>&1 &
VNC_PID=$!

ddev exec "node puppeteer.js"

# Capture the exit status of the Puppeteer script
PUPPETEER_EXIT_STATUS=$?

# Kill the vncviewer process
kill $VNC_PID

# Check the Puppeteer exit status and handle failure
if [ $PUPPETEER_EXIT_STATUS -ne 0 ]; then
  echo "Puppeteer test failed. Exiting."
  exit 1
fi
