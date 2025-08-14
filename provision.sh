#!/usr/bin/env bash
set -euo pipefail

# Simple provisioning for Azure resources used by the Static Web App API.
# Requires: Azure CLI (az). Optional: Azure Static Web Apps CLI (swa).

echo "== Azure login =="
if ! az account show >/dev/null 2>&1; then
  az login
fi

read -rp "Subscription ID (leave blank to use current): " SUBS || true
if [ -n "${SUBS:-}" ]; then az account set --subscription "$SUBS"; fi

RG=${RG:-portfolio-swa-rg}
read -rp "Resource group name [${RG}]: " RG_IN || true; RG=${RG_IN:-$RG}

LOC=${LOC:-westeurope}
read -rp "Azure region (e.g., westeurope, uksouth) [${LOC}]: " LOC_IN || true; LOC=${LOC_IN:-$LOC}

SA="swa$(openssl rand -hex 4)"
COSMOS="cosmos$(openssl rand -hex 4)"

echo "== Creating resource group $RG in $LOC =="
az group create -n "$RG" -l "$LOC" >/dev/null

echo "== Creating Storage account $SA =="
az storage account create -n "$SA" -g "$RG" -l "$LOC" --sku Standard_LRS >/dev/null
KEY=$(az storage account keys list -n "$SA" -g "$RG" --query "[0].value" -o tsv)
az storage container create --name uploads --account-name "$SA" --auth-mode key >/dev/null

echo "== Creating Cosmos DB account $COSMOS (SQL API) =="
az cosmosdb create -n "$COSMOS" -g "$RG" --kind GlobalDocumentDB >/dev/null
az cosmosdb sql database create -a "$COSMOS" -g "$RG" -n portfolio >/dev/null
az cosmosdb sql container create -a "$COSMOS" -g "$RG" -d portfolio -n files --partition-key-path "/id" --throughput 400 >/dev/null
COSMOS_CONN=$(az cosmosdb keys list -n "$COSMOS" -g "$RG" --type connection-strings --query "connectionStrings[0].connectionString" -o tsv)

echo ""
echo "== Storage =="
echo "  STORAGE_ACCOUNT_NAME=$SA"
echo "  STORAGE_ACCOUNT_KEY=(hidden)"
echo "  BLOB_CONTAINER=uploads"
echo "== Cosmos =="
echo "  COSMOS_CONNECTION=(hidden)"
echo ""

echo "Now create or identify your Static Web App name."
read -rp "Static Web App name (existing or to create in Portal): " SWA

echo ""
echo "-> If the SWA already exists, I'll set the environment variables on it."
echo "   Otherwise, create it in the Azure Portal (Static Web Apps) and then press ENTER."
read -rp "Press ENTER when the SWA exists..." _

echo "== Setting SWA app settings =="
az staticwebapp appsettings set -n "$SWA" -g "$RG" --setting-names COSMOS_CONNECTION="$COSMOS_CONN" STORAGE_ACCOUNT_NAME="$SA" STORAGE_ACCOUNT_KEY="$KEY" BLOB_CONTAINER="uploads" >/dev/null
echo "Done. App settings configured for SWA: $SWA"

echo ""
echo "Optional: deploy from local using SWA CLI (swa)."
if command -v swa >/dev/null 2>&1; then
  read -rp "Deploy now with 'swa deploy'? [y/N]: " DEP || true
  if [[ "${DEP,,}" == "y" ]]; then
    swa deploy --env production --app-location . --api-location api
  fi
else
  echo "Install SWA CLI: npm i -g @azure/static-web-apps-cli"
fi

echo "All set! Push this repo to GitHub and/or connect it to SWA via the Azure Portal for CI/CD."
