using './aistudio-main.bicep'

param aiServicesCustomSubDomainName = ''
param keyVaultEnablePurgeProtection = false
param acrEnabled = true
param acrName = 'mediumpostacr0035'
param aiServicesName = 'mediumpostaiservices0035'
param applicationInsightsName = 'mediumpostappinsights0035'
param keyVaultName = 'mediumpostkv00035'
param logAnalyticsName = 'mediumpostla0035'
param storageAccountName = 'mediumpostsa0035'
param hubName = 'mediumposthub0035'
param projectName = 'mediumpostproject0035'
param searchName = 'mediumpostsearch0035'

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
