param eventGridSubName string = 'policyInsightsSub'
param topicName string = 'policyInsightsTopic'
param appName string
param functionAppResourceId string = '${resourceGroup().id}/providers/Microsoft.Web/sites/${appName}/functions/policyMonitor'

resource evtTopic 'Microsoft.EventGrid/systemTopics@2022-06-15' = {
  name: topicName
  location: 'global'
  properties: {
    source: subscription().id
    topicType: 'Microsoft.PolicyInsights.PolicyStates'
  }
}

resource evtGridSub 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2022-06-15' = {
  name: eventGridSubName
  parent: evtTopic
  properties: {
    eventDeliverySchema: 'EventGridSchema'
    destination: {
      endpointType: 'AzureFunction'
      properties: {
        resourceId: functionAppResourceId
        maxEventsPerBatch: 1
				preferredBatchSizeInKilobytes: 64
      }
    }
    filter: {
      subjectBeginsWith: ''
      subjectEndsWith: ''
      includedEventTypes: [
        'Microsoft.PolicyInsights.PolicyStateChanged'
        'Microsoft.PolicyInsights.PolicyStateCreated'
        'Microsoft.PolicyInsights.PolicyStateDeleted'
      ]
      enableAdvancedFilteringOnArrays: true
    }
  }
}

output evtGridSubId string = evtGridSub.id
