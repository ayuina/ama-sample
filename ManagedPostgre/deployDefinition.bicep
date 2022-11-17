param definitionName string = 'ManagedPostgre-V2'
param packageUrl string
param region string = 'japaneast'
param ownerPrincipalId string
param contributorPrincipalId string

var ownerRoleId = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource managedAppDef 'Microsoft.Solutions/applicationDefinitions@2021-07-01' = {
  name: definitionName
  location: region
  properties: {
    lockLevel: 'ReadOnly'
    displayName: 'Managed PostgreSQL Flexible Server in VNET'
    description: '指定した VNET に Postgre をデプロイします'   
    packageFileUri: packageUrl
    managementPolicy: { mode: 'Managed'}
    lockingPolicy:{
      allowedActions: [
        'Microsoft.DBforPostgreSQL/*'
      ]
      allowedDataActions: []
    }
    notificationPolicy: null
    deploymentPolicy: { deploymentMode: 'Complete' }
    authorizations: [
      {
        principalId: ownerPrincipalId
        roleDefinitionId: ownerRoleId
      }
      {
        principalId: contributorPrincipalId
        roleDefinitionId: contributorRoleId
      }
    ]

  }
}
