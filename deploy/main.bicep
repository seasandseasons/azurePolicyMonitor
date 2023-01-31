param logAnalyticsNamespaceName string
param storageAccountName string
param location string

@description('Storage SKU')
param skuName string

@description('Resource Group name for this deployment')
param rgName string

param appInsightsName string
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
param linuxFxVersion string

@description('Function App name')
param appName string

param runtime string
param functionAppKeySecretName string
param logAnalysticsWorkspaceSecretName string

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

module appInsights 'modules/appInsights.bicep' = {
  name: 'appInsightsDeployment'
  scope: rg
  params: {
    location: location
    appInsightsName: appInsightsName
    logAnalyticsNamespaceName: logAnalyticsNamespaceName
  }
}
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyvaultName
  scope: rg
} 

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
  dependsOn: [ logAnalyticsWs ]
}
