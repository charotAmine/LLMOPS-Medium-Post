@description('Specifies the location for all Azure resources.')
param location string = resourceGroup().location

@description('Specifies the name of the Azure AI Hub workspace.')
param hubName string = ''

@description('Specifies the friendly name of the Azure AI Hub workspace.')
param hubFriendlyName string = 'Blog Medium Hub'

@description('Specifies the description of the Azure AI Hub workspace.')
param hubDescription string = 'Blog Medium for Azure AI Studio.'

@description('Specifies the isolation mode for the managed network of the Azure AI Hub workspace.')
@allowed(['AllowInternetOutbound', 'AllowOnlyApprovedOutbound', 'Disabled'])
param hubIsolationMode string = 'Disabled'

@description('Specifies the public network access for the Azure AI Hub workspace.')
param hubPublicNetworkAccess string = 'Enabled'

@description('Specifies the authentication method for the OpenAI Service connection.')
@allowed(['ApiKey', 'AAD', 'ManagedIdentity', 'None'])
param connectionAuthType string = 'ApiKey'

@description('Specifies the authentication mode for the system datastores of the workspace.')
@allowed(['identity', 'accessKey'])
param systemDatastoresAuthMode string = 'accessKey'

@description('Specifies the name for the Azure AI Studio Hub Project workspace.')
param projectName string = ''

@description('Specifies the friendly name for the Azure AI Studio Hub Project workspace.')
param projectFriendlyName string = 'AI Studio Hub Project'

@description('Specifies the public network access for the Azure AI Project workspace.')
param projectPublicNetworkAccess string = 'Enabled'

@description('Specifies the name of the Azure Log Analytics resource.')
param logAnalyticsName string = ''

@description('Specifies the service tier of the workspace.')
@allowed(['Free', 'Standalone', 'PerNode', 'PerGB2018'])
param logAnalyticsSku string = 'PerNode'

@description('Specifies the workspace data retention in days.')
param logAnalyticsRetentionInDays int = 60

@description('Specifies the name of the Azure Application Insights resource.')
param applicationInsightsName string = ''

@description('Specifies the name of the Azure AI Services resource.')
param aiServicesName string = ''

@description('Specifies the resource model definition representing SKU.')
param aiServicesSku object = { name: 'S0' }

@description('Specifies the identity of the Azure AI Services resource.')
param aiServicesIdentity object = { type: 'SystemAssigned' }

@description('Specifies an optional subdomain name used for token-based authentication.')
param aiServicesCustomSubDomainName string = ''

@description('Specifies whether to disable local authentication via API key.')
param aiServicesDisableLocalAuth bool = false

@description('Specifies whether public endpoint access is allowed for this account.')
@allowed(['Enabled', 'Disabled'])
param aiServicesPublicNetworkAccess string = 'Enabled'

@description('Specifies the OpenAI deployments to create.')
param openAiDeployments array = [
  {
    model: {
      name: 'text-embedding-ada-002'
      version: '2'
    }
    sku: {
      name: 'Standard'
      capacity: 10
    }
  }
  {
    model: {
      name: 'gpt-4o'
      version: '2024-05-13'
    }
    sku: {
      name: 'Standard'
      capacity: 10
    }
  }
]

@description('Specifies the name of the Azure Key Vault resource.')
param keyVaultName string = ''

@description('Specifies the default action of allow or deny when no other rules match for the Azure Key Vault resource.')
@allowed(['Allow', 'Deny'])
param keyVaultNetworkAclsDefaultAction string = 'Allow'

@description('Specifies whether the Azure Key Vault resource is enabled for deployments.')
param keyVaultEnabledForDeployment bool = true

@description('Specifies whether the Azure Key Vault resource is enabled for disk encryption.')
param keyVaultEnabledForDiskEncryption bool = true

@description('Specifies whether the Azure Key Vault resource is enabled for template deployment.')
param keyVaultEnabledForTemplateDeployment bool = true

@description('Specifies whether soft delete is enabled for this Azure Key Vault resource.')
param keyVaultEnableSoftDelete bool = true

@description('Specifies whether purge protection is enabled for this Azure Key Vault resource.')
param keyVaultEnablePurgeProtection bool = true

@description('Specifies whether to enable RBAC authorization for the Azure Key Vault resource.')
param keyVaultEnableRbacAuthorization bool = true

@description('Specifies the soft delete retention in days.')
param keyVaultSoftDeleteRetentionInDays int = 7

@description('Specifies whether to create the Azure Container Registry.')
param acrEnabled bool = false

@description('Specifies the name of the Azure Container Registry resource.')
param acrName string = ''

@description('Enable admin user that has push/pull permission to the registry.')
param acrAdminUserEnabled bool = false

@description('Tier of your Azure Container Registry.')
@allowed(['Basic', 'Standard', 'Premium'])
param acrSku string = 'Standard'

@description('Specifies the name of the Azure Storage Account resource.')
param storageAccountName string = ''

@description('Specifies the access tier of the Azure Storage Account resource.')
param storageAccountAccessTier string = 'Hot'

@description('Specifies whether the Azure Storage Account resource allows public access to blobs.')
param storageAccountAllowBlobPublicAccess bool = false

@description('Specifies whether the Azure Storage Account resource allows shared key access.')
param storageAccountAllowSharedKeyAccess bool = true

@description('Specifies whether the Azure Storage Account resource allows cross-tenant replication.')
param storageAccountAllowCrossTenantReplication bool = false

@description('Specifies the minimum TLS version to be permitted on requests to the Azure Storage Account resource.')
param storageAccountMinimumTlsVersion string = 'TLS1_2'

@description('Specifies the default action of allow or deny when no other rules match for the Azure Storage Account resource.')
@allowed(['Allow', 'Deny'])
param storageAccountANetworkAclsDefaultAction string = 'Allow'

@description('Specifies the resource tags for all resources.')
param tags object = {}

param searchName string = ''

@description('Service tier of the Azure Search')
param searchSku string = 'standard'

param searchAuthOption object = {}

module dependencies 'modules/dependent-resources.bicep' = {
  name: 'dependencyResources'
  params: {
    // acr parameters
    containerRegistryname: acrName
    location: location
    tags: tags
    acrSku: acrSku
    adminUserEnabled: acrAdminUserEnabled
    //applicationInsights parameters
    AppInsightsname: applicationInsightsName
    //logAnalytics parameters
    logAnalyticsWorkspacename: logAnalyticsName
    lasku: logAnalyticsSku
    retentionInDays: logAnalyticsRetentionInDays
    //vault Parameters
    keyVaultname: keyVaultName
    vaultNetworkAclsDefaultAction: keyVaultNetworkAclsDefaultAction
    enabledForDeployment: keyVaultEnabledForDeployment
    enabledForDiskEncryption: keyVaultEnabledForDiskEncryption
    enabledForTemplateDeployment: keyVaultEnabledForTemplateDeployment
    enablePurgeProtection: keyVaultEnablePurgeProtection
    enableRbacAuthorization: keyVaultEnableRbacAuthorization
    enableSoftDelete: keyVaultEnableSoftDelete
    softDeleteRetentionInDays: keyVaultSoftDeleteRetentionInDays
    //ai parameters
    aiName: aiServicesName
    aiSku: aiServicesSku
    aiServicesIdentity: aiServicesIdentity
    customSubDomainName: aiServicesCustomSubDomainName
    disableLocalAuth: aiServicesDisableLocalAuth
    publicNetworkAccess: aiServicesPublicNetworkAccess
    deployments: openAiDeployments
    //storage parameters
    storageName: storageAccountName
    accessTier: storageAccountAccessTier
    allowBlobPublicAccess: storageAccountAllowBlobPublicAccess
    allowSharedKeyAccess: storageAccountAllowSharedKeyAccess
    allowCrossTenantReplication: storageAccountAllowCrossTenantReplication
    minimumTlsVersion: storageAccountMinimumTlsVersion
    storageNetworkAclsDefaultAction: storageAccountANetworkAclsDefaultAction
    //search parameters
    searchName: searchName
    searchSku: searchSku
    searchAuthOption: searchAuthOption
  }
}

module hub 'modules/ai-hub.bicep' = {
  name: 'hub'
  params: {
    hubName: hubName
    friendlyhubName: hubFriendlyName
    descriptionHub: hubDescription
    location: location
    tags: tags

    // dependent resources
    aiServiceshubName: dependencies.outputs.ainame
    applicationInsightsId: dependencies.outputs.applicationInsightsid
    containerRegistryId: acrEnabled ? dependencies.outputs.containerRegistryid : ''
    keyVaultId: dependencies.outputs.keyVaultid
    storageAccountId: dependencies.outputs.storageId
    connectionAuthType: connectionAuthType
    systemDatastoresAuthMode: systemDatastoresAuthMode
    aiServicesConnectionhubEndpoint: dependencies.outputs.openAiEndpoint
    // workspace configuration
    publicNetworkAccess: hubPublicNetworkAccess
    isolationMode: hubIsolationMode
    searchName: dependencies.outputs.searchName
  }
}

module project 'modules/ai-hub-project.bicep' = {
  name: 'project'
  params: {
    projectName: projectName
    friendlyName: projectFriendlyName
    location: location
    tags: tags
    publicNetworkAccess: projectPublicNetworkAccess
    hubId: hub.outputs.id
    aiServicesPrincipalId: dependencies.outputs.aiprincipalId
  }
}
