```powershell

$app = 'ManagedStorage'
$blob = "${app}.zip"
$zip = ".\${blob}"

Remove-Item .\*.zip
Compress-Archive -Path .\mainTemplate.json, .\createUiDefinition.json -DestinationPath $zip

$stracc = 'amadefstr1110'
$container = 'temp'
az storage blob upload --account-name $stracc --container-name $container --name $blob --auth-mode login --file $zip --overwrite
Remove-Item $zip

$exp = [DateTimeOffset]::UtcNow.AddHours(1).ToString("s") + "Z"
az storage blob generate-sas  --account-name $stracc --container-name $container --name $blob --permission r --expiry $exp --auth-mode login --as-user --full-uri | sv packurl
echo $packurl

function deployDefinition($locklevel, $appdefpackurl)
{
    $operatorid = '7498682b-b56d-418f-96ee-fcaa958f34f1' #yamaguchi
    $roleid = 'b24988ac-6180-42a0-ab88-20f7382dd24c' #contributor
    $amadefrg = 'ama-def-rg'
    $region = 'japaneast'
    $def = "ManagedStorage-${locklevel}"

    az managedapp definition create -n $def -g $amadefrg -l $region `
        --display-name "Managed storage ${locklevel} lock level" `
        --description "This is Managed Application sample for ${locklevel}" `
        --lock-level $locklevel `
        --authorization "${operatorid}:${roleid}" `
        --package-file-uri $appdefpackurl

    echo "Managed Application Definition : ${def}"
}


deployDefinition -locklevel 'ReadOnly' -appdefpackurl $packurl
deployDefinition -locklevel 'CanNotDelete' -appdefpackurl $packurl
deployDefinition -locklevel 'None' -appdefpackurl $packurl

```

