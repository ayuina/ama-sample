param prefix string = 'ayuina'
param region string = 'japaneast'

param adminName string = prefix
@secure()
param adminPassword string

var vnetname = 'infra-vnet'
var vmsubnetName = 'default'
var vmname = '${prefix}-vm'
var postgreSubnetName = 'postgre-subnet'
var privateDnsZoneName = '${prefix}.private.postgres.database.azure.com'

resource vnet 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: vnetname
  location: region
  properties: {
    addressSpace: {
      addressPrefixes: ['10.20.0.0/16']
    }
    subnets: [
      {
        name: vmsubnetName
        properties:{
          addressPrefix: '10.20.0.0/24'
          networkSecurityGroup: { id: vmnsg.id}
        }
      }
      {
        name: postgreSubnetName
        properties:{
          addressPrefix: '10.20.128.0/24'
          networkSecurityGroup: { 
            id:postgreNsg.id 
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
              locations: ['japaneast', 'japanwest']
            }
          ]
          delegations:[
            {
              name: 'delegate-postgresql-flexibleserver'
              properties:{
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
        }
      }
    ]
  }
}

resource postgreNsg 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: 'postgre-nsg'
  location: region
  properties:{
    securityRules:[
      {
        name: 'AllowInboundToPostgre'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 1000
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [ '5432','6432' ]
        }
      }
      {
        name: 'AllowPostgreLogArchiveToStorage'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 1000
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Storage'
          destinationPortRanges:['443']
        }
      }
    ]
  }
}

resource vmnsg 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: 'virtual-machine-nsg'
  location: region
  properties:{
    securityRules:[
      {
        name: 'AllowInboundRdp'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 1000
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [ '3389' ]
        }
      }
      {
        name: 'AllowInboundSsh'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 1010
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [ '22' ]
        }
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateDnsZoneName}-link'
  parent: privateDnsZone
  location: 'global'
  properties:{
    registrationEnabled: false
    virtualNetwork:{
      id : vnet.id
    }
  } 
}

resource pip 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: '${vmname}-pip'
  location: region
  sku: { name: 'Standard' }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: { domainNameLabel: '${vmname}-${uniqueString(resourceGroup().id)}' }
  }
}

resource vmsubnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' existing = {
  parent: vnet
  name: vmsubnetName
}

resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: '${vmname}-nic'
  location: region
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: vmsubnet.id
          }
        }
      }
    ]
  }
}


resource testvm 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: vmname
  location: region
  properties: {
    hardwareProfile: { vmSize: 'Standard_B2s' }
    osProfile: {
      computerName: vmname
      adminUsername: adminName
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: { 
        publisher: 'canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks:[]
    }
    networkProfile: {
      networkInterfaces:[ {id: nic.id} ]
    }
  }
}

resource postgreSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' existing = {
  parent: vnet
  name: postgreSubnetName
}

output postgreSubnetId string = postgreSubnet.id
output privateDnsZoneId string = privateDnsZone.id
