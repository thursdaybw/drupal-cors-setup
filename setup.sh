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

# Default script directory
# Get the full path to the script, regardless of where it is being called from
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Source the common configuration file
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/common-config.sh"

#source "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/setup-backend.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/setup-frontend.sh"

# Final output
echo "Setup completed for project $PROJECT_NAME with CORS method $CORS_METHOD."
echo "DDEV environments created:"
ddev describe $CORS_ENV 
ddev describe $FRONTEND_ENV
