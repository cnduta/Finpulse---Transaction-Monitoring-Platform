// =============================================================
// FinPulse — Core Infrastructure
// Provisions: ADLS Gen2 storage, Event Hubs namespace, Key Vault
// =============================================================

@description('Short project name used as a naming prefix')
param projectName string = 'finpulse'

@description('Environment name: dev, test, or prod')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Azure region for all resources')
param location string = 'uksouth'

// A short unique suffix so globally-unique resource names (storage, key vault)
// don't clash with other Azure customers. Deterministic per resource group,
// so re-running the deployment doesn't generate a new name each time.
var uniqueSuffix = uniqueString(resourceGroup().id)

var storageAccountName = toLower('${projectName}sa${environment}${substring(uniqueSuffix, 0, 10)}')
var keyVaultName = toLower('${projectName}-kv-${environment}-${substring(uniqueSuffix, 0, 8)}')
var eventHubNamespaceName = toLower('${projectName}-ehns-${environment}-${uniqueSuffix}')

// -------------------------------------------------------------
// ADLS Gen2 Storage Account (Bronze/raw landing zone)
// -------------------------------------------------------------
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS' // Locally redundant storage — cheapest tier, fine for a dev/demo project
  }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true // This is what makes it "ADLS Gen2" rather than plain blob storage
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

// Containers for the Medallion layers, created inside the storage account
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

resource bronzeContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'bronze'
  properties: {
    publicAccess: 'None'
  }
}

resource rawStreamingContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'raw-streaming'
  properties: {
    publicAccess: 'None'
  }
}

// -------------------------------------------------------------
// Key Vault (secrets: Snowflake creds, connection strings)
// -------------------------------------------------------------
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true // Modern approach: use Azure RBAC roles instead of legacy access policies
    enableSoftDelete: true
    softDeleteRetentionInDays: 7 // Minimum allowed; keeps demo cleanup cheap/fast
  }
}

// -------------------------------------------------------------
// Event Hubs (streaming transaction ingestion)
// -------------------------------------------------------------
resource eventHubNamespace 'Microsoft.EventHub/namespaces@2023-01-01-preview' = {
  name: eventHubNamespaceName
  location: location
  sku: {
    name: 'Standard' // Basic tier doesn't support Capture or consumer groups we may want later
    tier: 'Standard'
    capacity: 1 // Throughput units — 1 is enough for a simulated demo workload
  }
  identity: {
    type: 'SystemAssigned' // Needed so Capture can write to ADLS without storage account keys
  }
  properties: {
    minimumTlsVersion: '1.2'
  }
}

// Storage Blob Data Contributor role, built into Azure — lets the Event Hubs
// namespace's managed identity write blobs into our storage account.
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

resource captureRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, eventHubNamespace.id, storageBlobDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
    principalId: eventHubNamespace.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2023-01-01-preview' = {
  parent: eventHubNamespace
  name: 'transactions'
  properties: {
    messageRetentionInDays: 1 // Demo project — keep retention (and cost) minimal
    partitionCount: 2 // Low partition count is fine for simulated single-producer traffic
    captureDescription: {
      enabled: true
      encoding: 'Avro'
      intervalInSeconds: 300 // Flush every 5 minutes...
      sizeLimitInBytes: 314572800 // ...or 300MB, whichever comes first
      destination: {
        name: 'EventHubArchive.AzureBlockBlob'
        properties: {
          storageAccountResourceId: storageAccount.id
          blobContainer: 'raw-streaming'
          // Folder structure Azure will create automatically inside the container
          archiveNameFormat: '{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}'
        }
      }
    }
  }
  dependsOn: [
    rawStreamingContainer
  ]
}

// Consumer group dedicated to the process that reads from Event Hubs into ADLS
resource consumerGroup 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2023-01-01-preview' = {
  parent: eventHub
  name: 'adls-writer'
}

output storageAccountName string = storageAccount.name
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
// -------------------------------------------------------------
// Azure Data Factory (batch ingestion, watermarked pipelines)
// -------------------------------------------------------------
var dataFactoryName = toLower('${projectName}-adf-${environment}-${uniqueSuffix}')

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: location
  identity: {
    type: 'SystemAssigned' // ADF will need this to read secrets from Key Vault and write to ADLS
  }
}

// Let ADF's managed identity read secrets from Key Vault (e.g. Snowflake creds later)
resource adfKeyVaultRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, dataFactory.id, 'secrets-user')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: dataFactory.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Let ADF write to the Bronze container
resource adfStorageRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, dataFactory.id, storageBlobDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
    principalId: dataFactory.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// -------------------------------------------------------------
// Azure SQL Database (serverless) — watermark control table
// -------------------------------------------------------------
@secure()
@description('Admin password for the SQL logical server. Pass via CLI param, never commit.')
param sqlAdminPassword string

var sqlServerName = toLower('${projectName}-sql-${environment}-${uniqueSuffix}')
var sqlAdminLogin = 'finpulseadmin'

resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    minimalTlsVersion: '1.2'
  }
}

// Allow Azure services (like ADF) to reach this server
resource sqlFirewallAllowAzure 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: 'finpulse-control'
  location: location
  sku: {
    name: 'GP_S_Gen5_1' // General Purpose Serverless, 1 vCore
    tier: 'GeneralPurpose'
  }
  properties: {
    autoPauseDelay: 60 // Pauses after 60 min idle — you pay ~nothing between runs
    minCapacity: json('0.5')
  }
}

output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseName string = sqlDatabase.name
output eventHubNamespaceName string = eventHubNamespace.name
output eventHubName string = eventHub.name
output dataFactoryName string = dataFactory.name
