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
cp "$SCRIPT_DIR/docker-compose.backend-alias.yml" .ddev/
# Configure Node.js version in DDEV
ddev config --nodejs-version="18"

# Create the index.html file in the frontend project
INDEX_FILE="$FRONTEND_PROJECT_DIR/index.html"

# Copy the HTML template to the working directory and replace placeholders
cp "$SCRIPT_DIR/index_template.html" "$INDEX_FILE"
sed -i "s#%%CORS_ENV%%#${CORS_ENV}#g" "$INDEX_FILE"
echo "index.html has been created in the $FRONTEND_PROJECT_DIR/ project at $INDEX_FILE"

ddev start
