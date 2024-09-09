// Parameters
@description('Specifies the name')
param projectName string

@description('Specifies the location.')
param location string

@description('Specifies the resource tags.')
param tags object

@description('Specifies the display name')
param friendlyName string = projectName

@description('Specifies the public network access for the machine learning workspace.')
param publicNetworkAccess string = 'Enabled'

@description('Specifies the AI hub resource id')
param hubId string

@description('Specifies the principal id of the Azure AI Services.')
param aiServicesPrincipalId string = ''


// Resources
resource project 'Microsoft.MachineLearningServices/workspaces@2024-04-01-preview' = {
  name: projectName
  location: location
  tags: tags
  kind: 'Project'
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: friendlyName
    hbiWorkspace: false
    v1LegacyMode: false
    publicNetworkAccess: publicNetworkAccess
    hubResourceId: hubId
    systemDatastoresAuthMode: 'identity'
  }
}

resource azureMLDataScientistRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'f6c7c914-8db3-469d-8ca1-694a8f32e121'
  scope: subscription()
}

resource azureMLDataScientistManagedIdentityRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(aiServicesPrincipalId)) {
  name: guid(project.id, azureMLDataScientistRole.id, aiServicesPrincipalId)
  scope: project
  properties: {
    roleDefinitionId: azureMLDataScientistRole.id
    principalType: 'ServicePrincipal'
    principalId: aiServicesPrincipalId
  }
}

// Outputs
output name string = project.name
output id string = project.id
output principalId string = project.identity.principalId
