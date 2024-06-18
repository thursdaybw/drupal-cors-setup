# Default script directory
# Get the full path to the script, regardless of where it is being called from
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Default workspace directory same as script directory
WORKSPACE_DIR="$SCRIPT_DIR"

# Default values
CORS_METHOD="apache"
PROJECT_NAME="drupal-headless"

