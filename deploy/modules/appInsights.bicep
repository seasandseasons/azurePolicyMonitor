@description('Resource group location')
param location string

@description('Application Insights name')
param appInsightsName string

@description('Log Analytics Workspace name')
param logAnalyticsNamespaceName string

// Reference an existing Log Analytics workspace by name
resource logAnalyticsWsReference 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsNamespaceName
}

// Create an Application Insights resource
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    Request_Source: 'rest'
    Flow_Type: 'Bluefield'
    WorkspaceResourceId: logAnalyticsWsReference.id
  }
}
