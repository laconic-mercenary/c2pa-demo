#!/bin/bash

set -euf -o pipefail

RESOURCE_GROUP_NAME="mattc2pa-rg01"
PYTHON_VERSION="3.11"

az login
cd certbot-generate
func azure functionapp publish mattc2pa-certbot-generate --build remote --python --python-version ${PYTHON_VERSION}
cd ..

# Deploy update function
cd certbot-update
func azure functionapp publish mattc2pa-certbot-update --build remote --python --python-version ${PYTHON_VERSION}
cd ..

# Deploy timer function
cd certbot-timer
func azure functionapp publish mattc2pa-cert-bot-time --build remote --python --python-version ${PYTHON_VERSION}
cd ..

# Deploy sas generator
cd sas-generator    
func azure functionapp publish mattc2pa-sas-generator --build remote --python --python-version ${PYTHON_VERSION}
cd ..