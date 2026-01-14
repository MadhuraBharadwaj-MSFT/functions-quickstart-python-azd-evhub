param name string
param location string = resourceGroup().location
param tags object = {}
param eventHubName string = 'news'
param partitionCount int = 32
param retentionInDays int = 1
param vnetEnabled bool = false

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2023-01-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 1
  }
  properties: {
    disableLocalAuth: true
    publicNetworkAccess: vnetEnabled ? 'Disabled' : 'Enabled'
    minimumTlsVersion: '1.2'
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2023-01-01-preview' = {
  parent: eventHubNamespace
  name: eventHubName
  properties: {
    partitionCount: partitionCount
    messageRetentionInDays: retentionInDays
  }
}

output eventHubNamespaceName string = eventHubNamespace.name
output eventHubNamespaceId string = eventHubNamespace.id
output eventHubName string = eventHub.name
