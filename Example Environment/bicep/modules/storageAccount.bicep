/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Azure Data Lake Storage Gen2
//
//        Storage for the Synapse Workspace configuration data along with any example data for on-demand querying and ingestion.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

targetScope = 'resourceGroup'

param resourceSuffix string
param azureRegion string

// Azure Data Lake Storage Gen2: Storage for the Synapse Workspace configuration data and example data
//   Azure: https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts
resource synapseStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: 'synapsesync${resourceSuffix}'
  location: azureRegion
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    isHnsEnabled: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      resourceAccessRules: [
        {
          resourceId: '/subscriptions/${subscription().subscriptionId}/resourcegroups/${resourceGroup().name}/providers/Microsoft.Synapse/workspaces/*'
          tenantId: subscription().tenantId
        }
      ]
    }
    publicNetworkAccess: 'Enabled'
  }
}

// Storage Container for the Synapse Workspace config data
//   Azure: https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/blobservices/containers
resource synapseConfigStorageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${synapseStorageAccount.name}/default/config'
}

// Storage Container for any data to ingest or query on-demand
//   Azure: https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/blobservices/containers
resource synapseDataStorageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${synapseStorageAccount.name}/default/data'
}

output synapseStorageAccountName string = synapseStorageAccount.name
