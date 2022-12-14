param prefix string = 'ayuina'
param region string = 'japaneast'
param postgreServerName string = 'postgre1115c'
param adminName string = prefix
@secure()
param adminPassword string
param postgreVnetResourceGroup string
param postgreVnetName string
param postgreSubnetName string
param privateDnsZoneId string

var postgreSubnetId = resourceId(postgreVnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', postgreVnetName, postgreSubnetName)
var straccountName = 'str${uniqueString(resourceGroup().id)}'

resource postgreFlexible 'Microsoft.DBforPostgreSQL/flexibleServers@2021-06-01' = {
  name: postgreServerName
  location: region
  sku :{
    name: 'Standard_B2s'
    tier: 'Burstable'
  }
  properties:{
    version: '14'
    administratorLogin: adminName
    administratorLoginPassword: adminPassword
    network: {
      delegatedSubnetResourceId: postgreSubnetId
      privateDnsZoneArmResourceId: privateDnsZoneId
    }
    highAvailability: {
      mode: 'Disabled'
    }
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: straccountName
  location: region
  sku:{
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  tags: {
    tag1: 'test'    
  }
}

output postgreEndpoint string = postgreFlexible.properties.fullyQualifiedDomainName
output blobEndpoint string = storage.properties.primaryEndpoints.blob
output tableEndpoint string = storage.properties.primaryEndpoints.table
output queueEndpoint string = storage.properties.primaryEndpoints.queue
output fileEndpoint string = storage.properties.primaryEndpoints.file

