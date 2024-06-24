# Default workspace directory same as script directory
WORKSPACE_DIR="$SCRIPT_DIR"

# Default values
CORS_METHOD="apache"
PROJECT_NAME="drupal-headless"

# Function to display help text
display_help() {
    echo "Usage: $0 [options...]"
    echo
    echo "   --cors-method [apache|drupal]   Specify how to configure CORS (default: apache)"
    echo "   --project-name <name>           Specify the project name (default: drupal-headless)"
    echo "   --workspace-dir <path>          Specify the workspace directory (default: directory of this script)"
    echo "   --help                          Display this help text"
    echo
    exit 1
}

# Parse command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --cors-method)
            if [[ "$2" == "apache" || "$2" == "drupal" ]]; then
                CORS_METHOD="$2"
                shift 2
            else
                echo "Error: Invalid value for --cors-method. Use 'apache' or 'drupal'."
                display_help
            fi
            ;;
        --project-name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --workspace-dir)
            WORKSPACE_DIR="$2"
            shift 2
            ;;
        --help)
            display_help
            ;;
        *)
            echo "Error: Invalid option $1"
            display_help
            ;;
    esac
done

echo "Using workspace directory: $WORKSPACE_DIR"

# Set up directories and project names
CORS_ENV="${PROJECT_NAME}-backend"
FRONTEND_ENV="${PROJECT_NAME}-frontend"
PUPPETEER_ENV="${PROJECT_NAME}-puppeteer"

# Set up directory variables
CORS_PROJECT_DIR="$WORKSPACE_DIR/$CORS_ENV"
FRONTEND_PROJECT_DIR="$WORKSPACE_DIR/$FRONTEND_ENV"
PUPPETEER_PROJECT_DIR="$WORKSPACE_DIR/$PUPPETEER_ENV"


