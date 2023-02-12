// @description('The name of the function app that you wish to create.')
// param appName string = 'fnapp-policy-compliance-${uniqueString(resourceGroup().id)}'
@description('The name of the function app that you wish to create.')
param appName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The language worker runtime to load in the function app.')
@allowed([
  'node'
  'dotnet'
  'java'
  'python'
])
param runtime string = 'python'
param linuxFxVersion string
param storageAccountName string
param keyvaultName string
param appInsightsName string
param functionAppKeySecretName string
param logAnalyticsNamespaceName string

@secure()
param logAnaWsKey string

var functionAppName = appName
var hostingPlanName = appName
var functionWorkerRuntime = runtime
var tenantId = '2373466a-a251-4a33-8eb7-b6ef9871f0ee'

resource stg 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource logAnaWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsNamespaceName
}

resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: hostingPlanName
  location: location
  kind: 'linux'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true
    maximumElasticWorkerCount: 1
    targetWorkerCount: 0
    targetWorkerSizeId: 0
  }
}

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${stg.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${stg.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionWorkerRuntime
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'ENABLE_ORYX_BUILD'
          value: 'true'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'WORKSPACE_ID'
          value: logAnaWorkspace.properties.customerId
        }
        {
          name: 'WORKSPACE_KEY'
          value: logAnaWsKey
        }
      ]
      cors: {
        allowedOrigins: [
            '*'
        ]
      }
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      linuxFxVersion: linuxFxVersion
      use32BitWorkerProcess: false
    }
    httpsOnly: true
    clientAffinityEnabled: false
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyvaultName
}

resource keyVaultAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
      objectId: functionApp.identity.principalId
      tenantId: tenantId
      permissions: {
        secrets: [
          'all'
        ]
      }
      }
    ] 
  }
}

resource keyvaultSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: functionAppKeySecretName 
  properties: {
    value: listKeys('${functionApp.id}/host/default', functionApp.apiVersion).functionKeys.default
  }
}
