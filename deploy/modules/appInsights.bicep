param location string
param appInsightsName string
param logAnalyticsNamespaceName string

resource logAnalyticsWsReference 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsNamespaceName
}

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
