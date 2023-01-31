param location string = resourceGroup().location
param keyvaultName string
param tenantId string
param enabledForDeployment bool
param enabledForTemplateDeployment bool
param enabledForDiskEncryption bool
param enabledRbacAuthorization bool
param accessPolicies array
param publicNetworkAccess string
param enableSoftDelete bool
param softDeleteRetentionInDays int
param networkAcls object

resource kv 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyvaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enableRbacAuthorization: enabledRbacAuthorization
    accessPolicies: accessPolicies
    publicNetworkAccess: publicNetworkAccess
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    networkAcls: networkAcls
  }
}
