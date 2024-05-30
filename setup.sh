#!/bin/bash

# Set up directory variables
WORKSPACE_DIR="$HOME/workspace"
CORS_PROJECT_DIR="$WORKSPACE_DIR/ashley-cors"
FRONTEND_PROJECT_DIR="$WORKSPACE_DIR/ashley-frontend"

# Function to create services.yml with CORS configuration in Drupal project
create_services_yml() {
  local DIR="$1/web/sites/default"
  local FILE="$DIR/services.yml"

  # Check if the directory exists
  if [ ! -d "$DIR" ]; then
    echo "Directory $DIR does not exist. Creating it..."
    mkdir -p "$DIR"
  fi

  # Write the CORS configuration to the services.yml file
  cat <<EOL > "$FILE"
parameters:
  cors.config:
    enabled: false
    # Specify allowed headers, like 'x-allowed-header'.
    allowedHeaders: []
    # Specify allowed request methods, specify ['*'] to allow all possible ones.
    allowedMethods: []
    # Configure requests allowed from specific origins. Do not include trailing
    # slashes with URLs.
    allowedOrigins: ['*']
    # Configure requests allowed from origins, matching against regex patterns.
    allowedOriginsPatterns: []
    # Sets the Access-Control-Expose-Headers header.
    exposedHeaders: false
    # Sets the Access-Control-Max-Age header.
    maxAge: false
    # Sets the Access-Control-Allow-Credentials header.
    supportsCredentials: false
EOL

  echo "CORS configuration has been written to $FILE"
}

# Create the ashley-cors DDEV project and set up Drupal
echo "Creating the ashley-cors DDEV environment..."
mkdir -p "$CORS_PROJECT_DIR"
cd "$CORS_PROJECT_DIR" || exit

# Initialize DDEV project
ddev config --project-type=drupal --php-version=8.3 --docroot=web
ddev start

# Install Drupal using Composer
ddev composer create drupal/recommended-project:^10
ddev config --update
ddev composer require drush/drush
ddev composer require drupal/jsonapi_extras drupal/simple_oauth

# Set up CORS configuration
create_services_yml "$CORS_PROJECT_DIR"

# Install Drupal using drush
ddev drush si standard --account-name=admin --account-pass=admin --site-name="Ashley Cors" -y

# Enable required modules
ddev drush en jsonapi jsonapi_extras simple_oauth -y

# Configure Simple OAuth
#ddev drush config-set simple_oauth.settings oauth2_enforce_authorization 1 -y

# Create the ashley-frontend DDEV environment
echo "Creating the ashley-frontend DDEV environment..."
mkdir -p "$FRONTEND_PROJECT_DIR"
cd "$FRONTEND_PROJECT_DIR" || exit

ddev config --project-type php --project-name ashley-frontend --docroot .
ddev start

# Create the index.html file in the ashley-frontend project
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

            fetch('http://ashley-cors.ddev.site/oauth/token', {
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
                    fetch('http://ashley-cors.ddev.site/jsonapi/node/article', {
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

ddev describe ashley-cors
ddev describe ashley-frontend
