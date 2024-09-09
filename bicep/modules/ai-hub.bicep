// Parameters
@description('Specifies the hubName')
param hubName string

@description('Specifies the location.')
param location string

@description('Specifies the resource tags.')
param tags object

@description('The SKU hubName to use for the AI Studio Hub Resource')
param skuhubName string = 'Basic'

@description('The SKU tier to use for the AI Studio Hub Resource')
@allowed(['Basic', 'Free', 'Premium', 'Standard'])
param skuTier string = 'Basic'

@description('Specifies the display hubName')
param friendlyhubName string = hubName

@description('Specifies the description')
param descriptionHub string

@description('Specifies the Isolation mode for the managed network of a machine learning workspace.')
@allowed([
  'AllowInternetOutbound'
  'AllowOnlyApprovedOutbound'
  'Disabled'
])
param isolationMode string = 'Disabled'

@description('Specifies the public network access for the machine learning workspace.')
@allowed([
  'Disabled'
  'Enabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Specifies the resource ID of the application insights resource for storing diagnostics logs')
param applicationInsightsId string

@description('Specifies the resource ID of the container registry resource for storing docker images')
param containerRegistryId string

@description('Specifies the resource ID of the key vault resource for storing connection strings')
param keyVaultId string

@description('Specifies the resource ID of the storage account resource for storing experimentation outputs')
param storageAccountId string

@description('Specifies thehubName of the Azure AI Services resource')
param aiServiceshubName string

@description('Specifies the authentication method for the OpenAI Service connection.')
@allowed([
  'ApiKey'
  'AAD'
  'ManagedIdentity'
  'None'
])
param connectionAuthType string = 'AAD'

@description('Specifies the hubName for the Azure OpenAI Service connection.')
param aiServicesConnectionhubName string = ''

@description('Specifies the Endpoint for the Azure OpenAI Service connection.')
param aiServicesConnectionhubEndpoint string = ''

@description('Determines whether or not to use credentials for the system datastores of the workspace workspaceblobstore and workspacefilestore. The default value is accessKey, in which case, the workspace will create the system datastores with credentials. If set to identity, the workspace will create the system datastores with no credentials.')
@allowed([
  'identity'
  'accessKey'
])
param systemDatastoresAuthMode string = 'identity'

param searchName string

// Resources
resource aiServices 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' existing = {
  name: aiServiceshubName
}

resource search 'Microsoft.Search/searchServices@2022-09-01' existing = {
  name: searchName
}

resource hub 'Microsoft.MachineLearningServices/workspaces@2024-04-01-preview' = {
  name: hubName
  location: location
  tags: tags
  sku: {
    name: skuhubName
    tier: skuTier
  }
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: friendlyhubName
    description: descriptionHub
    managedNetwork: {
      isolationMode: isolationMode
    }
    publicNetworkAccess: publicNetworkAccess
    keyVault: keyVaultId
    storageAccount: storageAccountId
    applicationInsights: applicationInsightsId
    containerRegistry: containerRegistryId == '' ? null : containerRegistryId
    systemDatastoresAuthMode: systemDatastoresAuthMode
  }

  resource aiServicesConnection 'connections@2024-01-01-preview' = {
    name: '${hubName}-connection'
    properties: {
      category: 'AIServices'
      target: aiServicesConnectionhubEndpoint
      authType: connectionAuthType
      isSharedToAll: true
      metadata: {
        ApiType: 'Azure'
        ResourceId: aiServices.id
      }
      credentials: connectionAuthType == 'ApiKey'
        ? {
            key: aiServices.listKeys().key1
          }
        : null
    }
  }

  resource searchServicesConnection 'connections@2024-01-01-preview' = {
    name: '${hubName}-search-connection'
    properties: {
      category: 'CognitiveSearch'
      target: 'https://${searchName}.search.windows.net'
      authType: connectionAuthType
      isSharedToAll: true
      metadata: {
        ResourceId: search.id
      }
      credentials: connectionAuthType == 'ApiKey'
        ? {
            key: search.listAdminKeys().primaryKey
          }
        : null
    }
  }
}


// Outputs
output hubName string = hub.name
output id string = hub.id
