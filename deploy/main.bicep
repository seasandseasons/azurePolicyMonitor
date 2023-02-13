@description('Log Analytics Workspace name')
param logAnalyticsNamespaceName string

@description('Storage Account name')
param storageAccountName string

@description('Resource region location')
param location string

@description('Storage SKU')
param skuName string

@description('Resource Group name for this deployment')
param rgName string

@description('Application Insights name')
param appInsightsName string

@description('Key Vault name')
param keyvaultName string

@description('Tenant ID')
param tenantId string

@description('Key Vault property')
param enabledForDeployment bool

@description('Key Vault property')
param enabledForTemplateDeployment bool

@description('Key Vault property')
param enabledForDiskEncryption bool

@description('Key Vault property')
param enabledRbacAuthorization bool

@description('Key Vault Access Policy')
param accessPolicies array

@description('Key Vault disable public access')
param publicNetworkAccess string

@description('Key Vault property')
param enableSoftDelete bool

@description('Key Vault property')
param softDeleteRetentionInDays int

@description('Key Vault property - Deny if IP not matched. Azure services can bypass.')
param networkAcls object

@description('Function App Python version')
param linuxFxVersion string

@description('Function App name')
param appName string

@description('Function worker runtime')
param runtime string

@description('Function App Key Vault secret name')
param functionAppKeySecretName string

@description('Log Analytics Workspace Key Vault secret name')
param logAnalysticsWorkspaceSecretName string

@description('Storage Account Sku')
@allowed([
  'StorageV2'
]
)
param storageAccountKind string

targetScope = 'subscription'

// Create resource group
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: location
}

// Deploy storage account using module
module stg 'modules/storage.bicep' = {
  name: 'storageDeployment'   // Deployed in the scope of resource group we created above
  scope: rg
  params: {
    storageAccountName: storageAccountName
    skuName: skuName
    location: location
    storageAccountKind: storageAccountKind
  }
}

// Deploy key vault using module
// Access for user, deployment Service Principal, functionapp
module kv 'modules/keyvault.bicep' = {
  name: keyvaultName
  scope: rg
  params: {
    location: location
    accessPolicies: accessPolicies
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enabledRbacAuthorization: enabledRbacAuthorization
    enableSoftDelete: enableSoftDelete
    keyvaultName: keyvaultName
    networkAcls: networkAcls
    publicNetworkAccess: publicNetworkAccess
    softDeleteRetentionInDays: softDeleteRetentionInDays
    tenantId: tenantId
  }
}

// Deploy log analytics workspace using module
// Access to keyvault for log analytics workspace
// Adds log analytics workspace primary key to keyvault
module logAnalyticsWs 'modules/logAnalyticsWs.bicep' = {
  name: 'logAnalyticsWsDeployment'
  scope: rg
  params: {
    location: location
    logAnalyticsNamespaceName: logAnalyticsNamespaceName
    keyvaultName: keyvaultName
    logAnalysticsWorkspaceSecretName: logAnalysticsWorkspaceSecretName
    //tenantId: tenantId
  }
}

// Deploy Application Insights resource for Function and connect to Log Analytics Workspace
module appInsights 'modules/appInsights.bicep' = {
  name: 'appInsightsDeployment'
  scope: rg
  params: {
    location: location
    appInsightsName: appInsightsName
    logAnalyticsNamespaceName: logAnalyticsNamespaceName
  }
}

// Reference existing Key Vault for functionApp module
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyvaultName
  scope: rg
} 

// Deploy Function App. Dependant on Log Analytics Workspace deployment
module functionApp 'modules/functionApp.bicep' = {
  name: 'functionAppDeployment'
  scope: rg
  params: {
    location: location
    linuxFxVersion: linuxFxVersion
    storageAccountName: storageAccountName
    keyvaultName: keyvaultName
    appName: appName
    runtime: runtime
    appInsightsName: appInsightsName
    functionAppKeySecretName: functionAppKeySecretName
    logAnalyticsNamespaceName: logAnalyticsNamespaceName
    logAnaWsKey: keyVault.getSecret(logAnalyticsWs.outputs.logAnalyticsWorkspaceSecretName)
  }
  dependsOn: [ 
    logAnalyticsWs
   ]
}

// Deploy Event Grid
module eventGrid 'modules/eventGrid.bicep' = {
  scope: rg
  name: 'eventGridDeployment'
  params: {
    appName: appName
  }
  dependsOn: [
    functionApp
  ]
}
