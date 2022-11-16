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


# Create Managed Application Definition（外部URLから定義をダウンロードする）

```powershell


$subsc = 'subscription-guid'
$region = 'japaneast'
$amadefrg = 'ama-def-rg'

$tag = '0.1'
$appdefpackurl = "https://github.com/ayuina/ama-sample/releases/download/${tag}/ManagedStorage.zip"

#authorization
$mrgrole = 'Storage Blob Data Owner'
az role definition list -n $mrgrole --query '[].name' -o tsv | sv roleid
az ad signed-in-user show --query 'id' -o tsv | sv operatorid

az managedapp definition create -n 'ManagedStorageGH' -g $amadefrg -l $region `
    --display-name "Managed storage from Github release" `
    --description "This is Managed Application sample for ghrelease" `
    --lock-level ReadOnly `
    --authorization "${operatorid}:${roleid}" `
    --package-file-uri $appdefpackurl

```
Managed Application Definition の作成

# Deploy PostgreSql with Managed Application


```powershell
$app = 'ManagedPostgre'
$src = ".\${app}\*.json"
$zip = ".\${app}.zip"
$blob = "${app}.zip"
Compress-Archive -Path $src -DestinationPath $zip

az storage blob upload --account-name $defstracc --container-name $defcontainer --auth-mode login --name $blob --file $zip --overwrite
az storage blob url --account-name $defstracc --container-name $defcontainer --auth-mode login --name $blob -o tsv | sv appdefpackurl
az storage blob upload --account-name $defstracc --container-name $defcontainer --auth-mode login --name 'ManagedPostgre.zip' --file '.\ManagedPostgre.zip' --overwrite
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
