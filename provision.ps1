Param(
  [string]$SubscriptionId,
  [string]$ResourceGroup = "portfolio-swa-rg",
  [string]$Location = "westeurope"
)

Write-Host "== Azure login =="
try { az account show | Out-Null } catch { az login | Out-Null }

if ($SubscriptionId) { az account set --subscription $SubscriptionId | Out-Null }

$rg = Read-Host "Resource group name [$ResourceGroup]"; if ($rg) { $ResourceGroup = $rg }
$loc = Read-Host "Azure region (e.g., westeurope, uksouth) [$Location]"; if ($loc) { $Location = $loc }

$sa = "swa" + (Get-Random -Maximum 9999999)
$cosmos = "cosmos" + (Get-Random -Maximum 9999999)

Write-Host "== Creating resource group $ResourceGroup in $Location =="
az group create -n $ResourceGroup -l $Location | Out-Null

Write-Host "== Creating Storage account $sa =="
az storage account create -n $sa -g $ResourceGroup -l $Location --sku Standard_LRS | Out-Null
$keys = az storage account keys list -n $sa -g $ResourceGroup --query "[0].value" -o tsv
az storage container create --name uploads --account-name $sa --auth-mode key | Out-Null

Write-Host "== Creating Cosmos DB account $cosmos (SQL API) =="
az cosmosdb create -n $cosmos -g $ResourceGroup --kind GlobalDocumentDB --enable-free-tier true | Out-Null
az cosmosdb sql database create -a $cosmos -g $ResourceGroup -n portfolio | Out-Null
az cosmosdb sql container create -a $cosmos -g $ResourceGroup -d portfolio -n files --partition-key-path "/id" --throughput 400 | Out-Null
$cosmosConn = az cosmosdb keys list -n $cosmos -g $ResourceGroup --type connection-strings --query "connectionStrings[0].connectionString" -o tsv

$SWA = Read-Host "Static Web App name (existing or to create in Portal)"

Read-Host "If needed, create the SWA in the Azure Portal now, then press ENTER to continue" | Out-Null

Write-Host "== Setting SWA app settings =="
az staticwebapp appsettings set -n $SWA -g $ResourceGroup --setting-names COSMOS_CONNECTION="$cosmosConn" STORAGE_ACCOUNT_NAME="$sa" STORAGE_ACCOUNT_KEY="$keys" BLOB_CONTAINER="uploads" | Out-Null
Write-Host "Done. App settings configured for SWA: $SWA"

if (Get-Command swa -ErrorAction SilentlyContinue) {
  $deploy = Read-Host "Deploy now with 'swa deploy'? [y/N]"
  if ($deploy.ToLower() -eq "y") {
    swa deploy --env production --app-location . --api-location api
  }
} else {
  Write-Host "Install SWA CLI: npm i -g @azure/static-web-apps-cli"
}
