#!/bin/bash
# This is a demo script designed to simplify the setup of a Drupal backend and frontend
# to demonstrate a basic headless Drupal configuration. The script provides the essential
# steps to set up CORS, simple_oauth for OAuth2.0-based authentication, and the
# Drupal JSON:API module for a RESTful web service.
#
# The script offers an option to configure CORS either through the Apache server or
# directly within Drupal's built-in settings. Configuring CORS in Apache is advantageous
# when dealing with multiple backend applications, as it allows for centralized management
# of CORS policies applicable across all services on the server. In contrast, configuring
# CORS directly in Drupal provides a more focused approach, suitable for specific
# Drupal instances where Apache-level configuration isn't necessary or preferred.
#
# Options:
#   --cors-method [apache|drupal] - Specifies the method to configure CORS, choosing between
#                                   web server level configuration (Apache) or application level
#                                   configuration (Drupal).
#   --project-name <name>         - Specifies the project name, defaulting to 'drupal-headless'.

# Function to display help text
display_help() {
    echo "Usage: $0 [options...]"
    echo
    echo "   --cors-method [apache|drupal]   Specify how to configure CORS (default: apache)"
    echo "   --project-name <name>           Specify the project name (default: drupal-headless)"
    echo "   --help                          Display this help text"
    echo
    exit 1
}

# Default values
CORS_METHOD="apache"
PROJECT_NAME="drupal-headless"

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
        --help)
            display_help
            ;;
        *)
            echo "Error: Invalid option $1"
            display_help
            ;;
    esac
done

# Set up directories and project names
CORS_ENV="${PROJECT_NAME}-backend"
FRONTEND_ENV="${PROJECT_NAME}-frontend"

# Set up directory variables
WORKSPACE_DIR="$HOME/workspace"
CORS_PROJECT_DIR="$WORKSPACE_DIR/$CORS_ENV"
FRONTEND_PROJECT_DIR="$WORKSPACE_DIR/$FRONTEND_ENV"

# Stop and delete backend project if it exists
if ddev describe $CORS_ENV &>/dev/null; then
  ddev stop $CORS_ENV 
  ddev delete $CORS_ENV --omit-snapshot -y
  rm -rf "$CORS_PROJECT_DIR"
fi

# Stop and delete frontend project if it exists
if ddev describe $FRONTEND_ENV &>/dev/null; then
  ddev stop $FRONTEND_ENV 
  ddev delete $FRONTEND_ENV --omit-snapshot -y
  rm -rf "$FRONTEND_PROJECT_DIR"
fi

# Create the backend DDEV project and set up Drupal
echo "Creating the $CORS_ENV DDEV environment..."
mkdir -p "$CORS_PROJECT_DIR"
cd "$CORS_PROJECT_DIR" || exit

# Set up CORS environment

# Configure CORS based on the chosen method
if [ "$CORS_METHOD" == "apache" ]; then
  ddev config --project-type=drupal --php-version=8.3 --docroot=web --webserver-type=apache-fpm
  echo "Setting up CORS in Apache configuration"

  # Create Apache configuration for CORS
  mkdir -p  .ddev/apache
  cat <<EOF > .ddev/apache/apache-site.conf
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/html/web

    <Directory /var/www/html/web>
        Options +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    <IfModule mod_headers.c>
        # Apache CORS configuration
     
	# Access-Control-Allow-Origin:
	#   This header specifies which origin domains are allowed to access the resource.
	#   The wildcard * means any domain can access the resource.
        Header set Access-Control-Allow-Origin "https://$FRONTEND_ENV.ddev.site"

        # Access-Control-Allow-Methods:
	#   This defines the HTTP methods (GET, POST, etc.) that are allowed when accessing the resources from other origins.
        Header set Access-Control-Allow-Methods "GET, POST"

        # Access-Control-Allow-Headers:
	#   Specifies the headers that can be used during the actual request.
	#   This is useful for making requests with credentials or specific content types.
        Header set Access-Control-Allow-Headers "Content-Type, Authorization"
    </IfModule>


    Alias "/phpstatus" "/var/www/phpstatus.php"
    <Location "/phpstatus">
        Require all granted
    </Location>

    ErrorLog /var/log/apache2/error.log
    CustomLog /var/log/apache2/access.log combined
</VirtualHost>
EOF

elif [ "$CORS_METHOD" == "drupal" ]; then
  ddev config --project-name $CORS_ENV --project-type drupal9 --docroot web --create-docroot
fi

# Install Drupal using Composer
ddev composer create drupal/recommended-project:^10
ddev config --update
ddev composer require drush/drush
ddev composer require drupal/jsonapi_extras drupal/simple_oauth

if [ "$CORS_METHOD" == "drupal" ]; then
    echo "Setting up CORS in Drupal services.yml"
    ddev exec tee /var/www/html/web/sites/default/services.yml > /dev/null <<EOF
parameters:
    cors.config:
      # Enables CORS configuration
      # This setting turns CORS rules on or off.
      enabled: true

      # Allows all headers
      # This defines which headers can be included in requests from other origins. ['*'] allows all headers.
      allowedHeaders: ['*']

      # Lists HTTP methods that are allowed
      # Specifies the HTTP methods allowed from other origins.
      allowedMethods: ['GET', 'POST']

      # Allows all origins
      # Defines the origins allowed to access the resource, with ['*'] meaning all origins are allowed.
      allowedOrigins: ['https://$FRONTEND_ENV.ddev.site']

      # Allows headers to be exposed to the browser
      # Allows the server to whitelist headers that browsers are allowed to access.
      exposedHeaders: ['Content-Type', 'Authorization']

      # Disables caching the result of the preflight request
      # This can define the time in seconds that the results of a preflight request can be cached, but false here disables caching.
      maxAge: false

      # Specifies that requests should not be made with credentials
      # Indicates whether the request can include user credentials like cookies or HTTP authentication.
      supportsCredentials: false
EOF
fi

ddev exec drush si -y --site-name="$CORS_ENV" --account-name=admin --account-pass=admin

# Enable required modules
ddev drush en jsonapi jsonapi_extras simple_oauth -y

## Create Oauth Keys
ddev drush simple-oauth:generate-keys ../keys

# Configure Simple OAuth Keys
ddev drush config-set simple_oauth.settings public_key /var/www/html/keys/public.key -y
ddev drush config-set simple_oauth.settings private_key /var/www/html/keys/private.key -y

cp "$WORKSPACE_DIR/cors-setup/create-consumer.php" .
ddev drush scr create-consumer.php


# Create the frontend DDEV environment
echo "Creating the $FRONEND_ENV DDEV environment..."
mkdir -p "$FRONTEND_PROJECT_DIR"
cd "$FRONTEND_PROJECT_DIR" || exit


# Initialize DDEV project
ddev config --project-type php --project-name $FRONTEND_ENV --docroot .
ddev start

# Create the index.html file in the frontend project
INDEX_FILE="$FRONTEND_PROJECT_DIR/index.html"

cat <<EOL > "$INDEX_FILE"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Drupal Headless Login</title>
</head>
<body>
    <h1>Login to Drupal</h1>
    <form id="login-form">
        <label for="username">Username:</label>
        <input type="text" id="username" name="username" required><br>
        <label for="password">Password:</label>
        <input type="password" id="password" name="password" required><br>
        <button type="submit">Login</button>
    </form>

    <h2 id="message"></h2>

    <script>
        document.getElementById('login-form').addEventListener('submit', function(event) {
            event.preventDefault();
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;

            fetch('https://${CORS_ENV}.ddev.site/oauth/token', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    grant_type: 'password',
                    client_id: 'your-client-id',
                    client_secret: 'your-client-secret',
                    username: username,
                    password: password
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.access_token) {
                    document.getElementById('message').innerText = 'Login successful!';
                    fetch('https://${CORS_ENV}.ddev.site/jsonapi/node/article', {
                        method: 'GET',
                        headers: {
                            'Authorization': 'Bearer ' + data.access_token
                        }
                    })
                    .then(response => response.json())
                    .then(data => {
                        console.log(data);
                        document.getElementById('message').innerText = 'Data fetched successfully!';
                    })
                    .catch(error => console.error('Error fetching data:', error));
                } else {
                    document.getElementById('message').innerText = 'Login failed!';
                }
            })
            .catch(error => console.error('Error during login:', error));
        });
    </script>
</body>
</html>
EOL

echo "index.html has been created in the ashley-frontend DDEV project at $INDEX_FILE"

# Final output
echo "Setup completed for project $PROJECT_NAME with CORS method $CORS_METHOD."
echo "DDEV environments created:"
ddev describe $CORS_ENV 
ddev describe $FRONTEND_ENV 
