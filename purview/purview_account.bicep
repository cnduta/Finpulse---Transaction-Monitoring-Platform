// FinPulse — Microsoft Purview Account
// Deploy separately: provisioning takes 20-30 min and rarely needs to be
// redeployed alongside the faster-changing core infra.

@description('Azure region')
param location string = 'uksouth'

@description('Short project name')
param projectName string = 'finpulse'

@description('Environment name')
param environment string = 'dev'

var uniqueSuffix = uniqueString(resourceGroup().id)
var purviewAccountName = toLower('${projectName}-purview-${environment}-${uniqueSuffix}')

resource purviewAccount 'Microsoft.Purview/accounts@2021-12-01' = {
  name: purviewAccountName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Standard'
    capacity: 4  // Minimum capacity units — fine for a demo-scale account
  }
}

output purviewAccountName string = purviewAccount.name
output purviewAtlasEndpoint string = purviewAccount.properties.endpoints.catalog
