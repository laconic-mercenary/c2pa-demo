#!/bin/bash

set -euf -o pipefail

RESOURCE_GROUP_NAME="mattc2pa-rg01"
FUNCTION_NAME="mattc2pa-certs"

az login

func azure functionapp publish ${FUNCTION_NAME} --build remote --python --python-version 3.11
