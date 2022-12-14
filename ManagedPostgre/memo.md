```powershell

$app = 'ManagedPostgre'
$ver = [DateTime]::Now.Ticks.ToString()
$def = "${app}-${ver}"
$blob = "${def}.zip"
$zip = ".\${blob}"

if(Test-Path .\mainTemplate.json)
{
    Remove-Item .\mainTemplate.json
}
az bicep build -f .\mainTemplate.bicep

Remove-Item .\*.zip
Compress-Archive -Path .\mainTemplate.json, .\createUiDefinition.json, .\viewDefinition.json -DestinationPath $zip
Remove-Item .\mainTemplate.json

$stracc = 'amadefstr1110'
$container = 'temp'
az storage blob upload --account-name $stracc --container-name $container --name $blob --auth-mode login --file $zip --overwrite
Remove-Item $zip

$exp = [DateTimeOffset]::UtcNow.AddHours(1).ToString("s") + "Z"
az storage blob generate-sas  --account-name $stracc --container-name $container --name $blob --permission r --expiry $exp --auth-mode login --as-user --full-uri | sv packurl
echo $packurl

az deployment group create -g 'ama-def-rg' -n "$([DateTime]::Now.Ticks)" -f .\deployDefinition.bicep -p packageUrl=$packurl definitionName=$def ownerPrincipalId=$ayumuInaba contributorPrincipalId=$shujiYamaguchi

echo "Managed Application Definition : ${def}"


```