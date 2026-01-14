param storageAccountName string
param eventHubNamespaceName string
param applicationInsightsName string
param managedIdentityPrincipalId string
param userIdentityPrincipalId string = ''
param allowUserIdentityPrincipal bool = false
param enableBlob bool = true
param enableQueue bool = false
param enableTable bool = false

var storageRoleDefinitionId = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b' // Storage Blob Data Owner
var queueRoleDefinitionId = '974c5e8b-45b9-4653-ba55-5f855dd0fb88' // Storage Queue Data Contributor
var tableRoleDefinitionId = '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3' // Storage Table Data Contributor
var eventHubsDataReceiverRoleDefinitionId = 'a638d3c7-ab3a-418d-83e6-5f17a39d4fde' // Event Hubs Data Receiver
var eventHubsDataSenderRoleDefinitionId = '2b629674-e913-4c01-ae53-ef4638d8f975' // Event Hubs Data Sender
var monitoringRoleDefinitionId = '3913510d-42f4-4e42-8a64-420c390055eb' // Monitoring Metrics Publisher

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' existing = {
  name: eventHubNamespaceName
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableBlob) {
  name: guid(storageAccount.id, managedIdentityPrincipalId, storageRoleDefinitionId)
  scope: storageAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', storageRoleDefinitionId)
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource queueRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableQueue) {
  name: guid(storageAccount.id, managedIdentityPrincipalId, queueRoleDefinitionId)
  scope: storageAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', queueRoleDefinitionId)
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource tableRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableTable) {
  name: guid(storageAccount.id, managedIdentityPrincipalId, tableRoleDefinitionId)
  scope: storageAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', tableRoleDefinitionId)
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource eventHubReceiveRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(eventHubNamespace.id, managedIdentityPrincipalId, eventHubsDataReceiverRoleDefinitionId)
  scope: eventHubNamespace
  properties: {
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', eventHubsDataReceiverRoleDefinitionId)
  }
}

resource eventHubSendRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(eventHubNamespace.id, managedIdentityPrincipalId, eventHubsDataSenderRoleDefinitionId)
  scope: eventHubNamespace
  properties: {
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', eventHubsDataSenderRoleDefinitionId)
  }
}

resource eventHubReceiveRoleAssignment_User 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (allowUserIdentityPrincipal && !empty(userIdentityPrincipalId)) {
  name: guid(eventHubNamespace.id, userIdentityPrincipalId, eventHubsDataReceiverRoleDefinitionId)
  scope: eventHubNamespace
  properties: {
    principalId: userIdentityPrincipalId
    principalType: 'User'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', eventHubsDataReceiverRoleDefinitionId)
  }
}

resource eventHubSendRoleAssignment_User 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (allowUserIdentityPrincipal && !empty(userIdentityPrincipalId)) {
  name: guid(eventHubNamespace.id, userIdentityPrincipalId, eventHubsDataSenderRoleDefinitionId)
  scope: eventHubNamespace
  properties: {
    principalId: userIdentityPrincipalId
    principalType: 'User'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', eventHubsDataSenderRoleDefinitionId)
  }
}

resource appInsightsRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(applicationInsights.id, managedIdentityPrincipalId, monitoringRoleDefinitionId)
  scope: applicationInsights
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', monitoringRoleDefinitionId)
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}
