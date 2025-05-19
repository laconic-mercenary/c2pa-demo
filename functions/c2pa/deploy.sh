#!/bin/bash

set -e -o pipefail

RESOURCE_GROUP="mattc2pa-rg01"

az login

cd c2pa

mvn clean package -DfunctionAppName="mattc2pa-sign"
mvn azure-functions:deploy -DfunctionAppName="mattc2pa-sign"

## There isn't a way using mvn deploy to filter the functions out
## for now, just deploy both functions to both funciton apps - will add this as TODO
mvn clean package -DfunctionAppName="mattc2pa-verify"
mvn azure-functions:deploy -DfunctionAppName="mattc2pa-verify"

cd ..