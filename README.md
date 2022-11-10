# ama-sample

PowerShell から Azure CLIを使用して操作して実施します。

# Setup Managed Application Publisher Environment

定義ファイルをアップロードするためのストレージを作成。
Publisher テナント側で一度用意すればよい。

```powershell
$subsc = 'subscription-guid'
$region = 'japaneast'
$amadefrg = 'ama-def-rg'
$defstracc = 'amadefstr1110'
$defcontainer = 'ama-definitions'

az login
az account set -s $subsc

az group create -g $amadefrg -l $region
az storage account create -g $amadefrg -n $defstracc -l $region --sku Standard_LRS --kind StorageV2
az storage container create --account-name $defstracc -n $defcontainer --auth-mode login --public-access blob

$blobcontributor = 'Storage Blob Data Contributor'
az role definition list -n $blobcontributor --query '[].id' -o tsv | sv blobconid
az ad signed-in-user show --query 'id' -o tsv | sv userid
az storage account show -g $amadefrg -n $defstracc --query 'id' -o tsv | sv defstraccid
az role assignment create --assignee $userid --role $blobconid --scope $defstraccid

```

# Create Managed Application Definition

Managed Application Definition の作成

```powershell
$app = 'ManagedStorage'
$src = ".\${app}\*"
$zip = ".\${app}.zip"
$blob = "${app}.zip"
Compress-Archive -Path $src -DestinationPath $zip
az storage blob upload --account-name $defstracc --container-name $defcontainer --auth-mode login --name $blob --file $zip --overwrite
az storage blob url --account-name $defstracc --container-name $defcontainer --auth-mode login --name $blob -o tsv | sv appdefpackurl


$mrgrole = 'Owner'
az role definition list -n $mrgrole --query '[].name' -o tsv | sv ownerroleid
az ad signed-in-user show --query 'id' -o tsv | sv operatorid

az managedapp definition create -n $app -g $amadefrg -l $region `
    --display-name "${app} display name" `
    --description "This is Managed Application sample for ${app}" `
    --lock-level ReadOnly `
    --authorization "${operatorid}:${ownerroleid}" `
    --package-file-uri $appdefpackurl

echo "open managed application center"
echo "https://portal.azure.com/#view/HubsExtension/AssetMenuBlade/~/overview/assetName/ApplicationsHub/extensionName/Microsoft_Azure_Appliance"
echo "or"
az account show --query 'tenantId' -o tsv | sv tenantid
echo "open managed definition resource"
echo "https://portal.azure.com/#@${tenantId}/resource/subscriptions/$subsc/resourceGroups/${amadefrg}/providers/Microsoft.Solutions/applicationDefinitions/${app}/overview"
```




