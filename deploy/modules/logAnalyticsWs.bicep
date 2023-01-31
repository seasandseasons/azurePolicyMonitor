param location string
param logAnalyticsNamespaceName string
param keyvaultName string
//param tenantId string
param logAnalysticsWorkspaceSecretName string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsNamespaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 120
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// resource keyVaultAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
//   name: '${keyvaultName}/add'
//   properties: {
//     accessPolicies: [
//       {
//       objectId: logAnalyticsWorkspace.identity.principalId
//       tenantId: tenantId
//       permissions: {
//         secrets: [
//           'all'
//         ]
//       }
//       }
//     ] 
//   }
// }

resource keyvaultSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: '${keyvaultName}/${logAnalysticsWorkspaceSecretName}' 
  properties: {
    value: listKeys(logAnalyticsWorkspace.id, logAnalyticsWorkspace.apiVersion).primarySharedKey
  }
}

output logAnalysticsWorkspaceId string = logAnalyticsWorkspace.properties.customerId
output logAnalyticsWSId string = logAnalyticsWorkspace.id
output logAnalyticsWorkspaceSecretName string = logAnalysticsWorkspaceSecretName 
