using './aistudio-main.bicep'

param aiServicesCustomSubDomainName = ''
param keyVaultEnablePurgeProtection = false
param acrEnabled = true
param acrName = 'mediumpostacr0025'
param aiServicesName = 'mediumpostaiservices0025'
param applicationInsightsName = 'mediumpostappinsights0025'
param keyVaultName = 'mediumpostkv0025'
param logAnalyticsName = 'mediumpostla0025'
param storageAccountName = 'mediumpostsa0025'
param hubName = 'mediumposthub0025'
param projectName = 'mediumpostproject0025'
param searchName = 'mediumpostsearch0025'

param openAiDeployments = [
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
      name: 'GlobalStandard'
      capacity: 10
    }
  }
]
param tags = {
  environment: 'dev'
}
