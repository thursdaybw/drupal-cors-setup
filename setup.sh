#!/bin/bash

# Set up directory variables
WORKSPACE_DIR="$HOME/workspace"
CORS_PROJECT_DIR="$WORKSPACE_DIR/ashley-cors"
FRONTEND_PROJECT_DIR="$WORKSPACE_DIR/ashley-frontend"

# Stop and delete ashley-cors project if it exists
if ddev describe ashley-cors &>/dev/null; then
  ddev stop ashley-cors
  ddev delete ashley-cors --omit-snapshot -y
  rm -rf ashley-cors
fi

# Stop and delete ashley-frontend project if it exists
if ddev describe ashley-frontend &>/dev/null; then
  ddev stop ashley-frontend
  ddev delete ashley-frontend --omit-snapshot -y
  rm -rf ashley-frontend
fi

# Create the ashley-cors DDEV project and set up Drupal
echo "Creating the ashley-cors DDEV environment..."
mkdir -p "$CORS_PROJECT_DIR"
cd "$CORS_PROJECT_DIR" || exit

# Initialize DDEV project
ddev config --project-type=drupal --php-version=8.3 --docroot=web --webserver-type=apache-fpm

# Create Apache configuration for CORS
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
        Header set Access-Control-Allow-Origin "*"
        Header set Access-Control-Allow-Methods "GET, POST, OPTIONS, DELETE, PUT"
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

ddev start

# Install Drupal using Composer
ddev composer create drupal/recommended-project:^10
ddev config --update
ddev composer require drush/drush
ddev composer require drupal/jsonapi_extras drupal/simple_oauth

# Install Drupal using drush
ddev drush si standard --account-name=admin --account-pass=admin --site-name="Ashley Cors" -y

# Enable required modules
ddev drush en jsonapi jsonapi_extras simple_oauth -y

# Configure Simple OAuth Keys
ddev drush config-set simple_oauth.settings public_key /var/www/html/keys/public.key -y
ddev drush config-set simple_oauth.settings private_key /var/www/html/keys/private.key -y
## Create Keys
ddev drush simple-oauth:generate-keys ../keys

cp "$WORKSPACE_DIR/cors-setup/create-consumer.php" .
ddev drush scr create-consumer.php

# Create the ashley-frontend DDEV environment
echo "Creating the ashley-frontend DDEV environment..."
mkdir -p "$FRONTEND_PROJECT_DIR"
cd "$FRONTEND_PROJECT_DIR" || exit

# Initialize DDEV project
ddev config --project-type php --project-name ashley-frontend --docroot . --webserver-type=apache-fpm
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

            fetch('https://ashley-cors.ddev.site/oauth/token', {
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
                    fetch('https://ashley-cors.ddev.site/jsonapi/node/article', {
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

