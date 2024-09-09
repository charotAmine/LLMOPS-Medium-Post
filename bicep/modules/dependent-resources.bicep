// Parameters
@description('Name of Azure Application Insights.')
param AppInsightsname string

@description('Location of the resource.')
param location string = resourceGroup().location

@description('Resource tags.')
param tags object

@description('Name of Azure Container Registry.')
@minLength(5)
@maxLength(50)
param containerRegistryname string = 'acr${uniqueString(resourceGroup().id)}'

@description('Enable admin user with push/pull permission to the registry.')
param adminUserEnabled bool = false

@description('Allow public network access. (Enabled/Disabled)')
@allowed([
  'Disabled'
  'Enabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Tier of Azure Container Registry.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSku string = 'Premium'

// Parameters
@description('Name of Key Vault resource.')
param keyVaultname string

@description('Sku name of Key Vault resource.')
@allowed([
  'premium'
  'standard'
])
param skuName string = 'standard'

@description('Azure Active Directory tenant ID for authentication.')
param tenantId string = subscription().tenantId

@description('Default action when no other rules match. (Allow/Deny)')
@allowed([
  'Allow'
  'Deny'
])
param vaultNetworkAclsDefaultAction string = 'Allow'

@description('Enable Key Vault for deployments.')
param enabledForDeployment bool = true

@description('Enable Key Vault for disk encryption.')
param enabledForDiskEncryption bool = true

@description('Enable Key Vault for template deployment.')
param enabledForTemplateDeployment bool = true

@description('Enable purge protection for Key Vault.')
param enablePurgeProtection bool = true

@description('Enable RBAC authorization for Key Vault.')
param enableRbacAuthorization bool = true

@description('Enable soft delete for Key Vault.')
param enableSoftDelete bool = true

@description('Soft delete retention in days.')
param softDeleteRetentionInDays int = 7

param logAnalyticsWorkspacename string

@description('Service tier of the workspace: Free, Standalone, PerNode, Per-GB.')
@allowed([
  'Free'
  'Standalone'
  'PerNode'
  'PerGB2018'
])
param lasku string = 'PerNode'

@description('Workspace data retention in days.')
param retentionInDays int = 60

@description('Name of the storage account.')
param storageName string

@description('Storage SKU.')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param storageSkuName string = 'Standard_LRS'

@description('Access tier of the storage account.')
param accessTier string = 'Hot'

@description('Allow public access to blobs.')
param allowBlobPublicAccess bool = false

@description('Allow shared key access.')
param allowSharedKeyAccess bool = false

@description('Allow cross-tenant replication.')
param allowCrossTenantReplication bool = false

@description('Minimum TLS version.')
param minimumTlsVersion string = 'TLS1_2'

@description('Default action when no other rules match. (Allow/Deny)')
@allowed([
  'Allow'
  'Deny'
])
param storageNetworkAclsDefaultAction string = 'Allow'

@description('Create containers.')
param createContainers bool = false

@description('Array of containers to create.')
param containerNames array = []

@description('Name of Azure AI Services account.')
param aiName string

@description('Resource model definition representing SKU.')
param aiSku object = {
  name: 'S0'
}

@description('Identity of the aiServices resource.')
param aiServicesIdentity object = {
  type: 'SystemAssigned'
}

@description('Optional subdomain name for token-based authentication.')
param customSubDomainName string = ''

@description('Disable local authentication via API key.')
param disableLocalAuth bool = true

@description('Allow public endpoint access for this account.')
@allowed([
  'Enabled'
  'Disabled'
])
param aiPublicNetworkAccess string = 'Enabled'

@description('OpenAI deployments to create.')
param deployments array = []

param searchName string = ''

@description('Service tier of the Azure Search')
param searchSku string = 'standard'

param searchAuthOption object = {}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: AppInsightsname
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    DisableIpMasking: false
    DisableLocalAuth: false
    Flow_Type: 'Bluefield'
    ForceCustomerStorageForProfiler: false
    ImmediatePurgeDataOn30Days: true
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Disabled'
    Request_Source: 'rest'
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' = {
  name: containerRegistryname
  location: location
  tags: tags
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: publicNetworkAccess
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultname
  location: location
  tags: tags
  properties: {
    createMode: 'default'
    sku: {
      family: 'A'
      name: skuName
    }
    tenantId: tenantId
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: vaultNetworkAclsDefaultAction
    }
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enablePurgeProtection: enablePurgeProtection ? enablePurgeProtection : null
    enableRbacAuthorization: enableRbacAuthorization
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
  }
}


resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: logAnalyticsWorkspacename
  tags: tags
  location: location
  properties: {
    sku: {
      name: lasku
    }
    retentionInDays: retentionInDays
  }
}


resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageName
  location: location
  tags: tags
  sku: {
    name: storageSkuName
  }
  kind: 'StorageV2'

  properties: {
    accessTier: accessTier
    allowBlobPublicAccess: allowBlobPublicAccess
    allowCrossTenantReplication: allowCrossTenantReplication
    allowSharedKeyAccess: allowSharedKeyAccess
    minimumTlsVersion: minimumTlsVersion
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: storageNetworkAclsDefaultAction
    }
  }
}

// Define blobService separately and link it to the storage account
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  name: '${storageAccount.name}/default'
}

// Define containers separately and link them to the blob service
resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = [
  for containerName in containerNames: if (createContainers) {
    name: '${storageAccount.name}/default/${containerName}'
    properties: {
      publicAccess: 'None'
    }
  }
]


resource storageBlobDataContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  scope: subscription()
}


resource storageBlobDataContributorManagedIdentityRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, storageBlobDataContributorRoleDefinition.id, aiServices.id)
  scope: storageAccount
  properties: {
    roleDefinitionId: storageBlobDataContributorRoleDefinition.id
    principalType: 'ServicePrincipal'
    principalId: aiServices.identity.principalId
  }
}


resource aiServices 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: aiName
  location: location
  sku: aiSku
  kind: 'AIServices'
  identity: aiServicesIdentity
  tags: tags
  properties: {
    customSubDomainName: customSubDomainName
    disableLocalAuth: disableLocalAuth
    publicNetworkAccess: aiPublicNetworkAccess
  }
}

@batchSize(1)
resource model 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [
  for deployment in deployments: {
    name: deployment.model.name
    parent: aiServices
    sku: {
      capacity: deployment.sku.capacity ?? 100
      name: empty(deployment.sku.name) ? 'Standard' : deployment.sku.name
    }
    properties: {
      model: {
        format: 'OpenAI'
        name: deployment.model.name
        version: deployment.model.version
      }
    }
  }
]

resource cognitiveServicesUserRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'a97b65f3-24c7-4388-baec-2e87135dc908'
  scope: subscription()
}


resource cognitiveServicesUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiServices.id, cognitiveServicesUserRoleDefinition.id, aiServices.id)
  scope: aiServices
  properties: {
    roleDefinitionId: cognitiveServicesUserRoleDefinition.id
    principalType: 'ServicePrincipal'
    principalId: aiServices.identity.principalId
  }
}

resource search 'Microsoft.Search/searchServices@2022-09-01' = {
  name: searchName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    authOptions: searchAuthOption
    disableLocalAuth: false
    hostingMode: 'default'
    networkRuleSet: {
      ipRules: []
    }
    partitionCount: 1
    publicNetworkAccess: 'enabled'
    replicaCount: 1
  }
  sku: {
    name: searchSku
  }
}

resource searchDataReader 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '1407120a-92aa-4202-b7e9-c0e197c71c8f'
  scope: subscription()
}

resource searchContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
  scope: subscription()
}

resource searchDataReaderAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiServices.id, searchDataReader.id, aiServices.id)
  scope: aiServices
  properties: {
    roleDefinitionId: searchDataReader.id
    principalType: 'ServicePrincipal'
    principalId: aiServices.identity.principalId
  }
}

resource searchContributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiServices.id, searchContributor.id, aiServices.id)
  scope: aiServices
  properties: {
    roleDefinitionId: searchContributor.id
    principalType: 'ServicePrincipal'
    principalId: aiServices.identity.principalId
  }
}

// Outputs
output keyVaultid string = keyVault.id
output keyVaultname string = keyVault.name
output containerRegistryid string = containerRegistry.id
output containerRegistryname string = containerRegistry.name
output applicationInsightsid string = applicationInsights.id
output applicationInsightsname string = applicationInsights.name
output logAnalyticsWorkspaceid string = logAnalyticsWorkspace.id
output logAnalyticsWorkspacename string = logAnalyticsWorkspace.name
output logAnalyticsWorkspacecustomerId string = logAnalyticsWorkspace.properties.customerId
output storageId string = storageAccount.id
output storageName string = storageAccount.name
output aiId string = aiServices.id
output ainame string = aiServices.name
output aiendpoint string = aiServices.properties.endpoint
output openAiEndpoint string = aiServices.properties.endpoints['OpenAI Language Model Instance API']
output aiprincipalId string = aiServices.identity.principalId
output searchId string = search.id
output searchName string = search.name
