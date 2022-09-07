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
    }
    publicNetworkAccess: 'Enabled'
  }
}

// Azure Data Lake Storage Gen2: Storage Container for the Synapse Workspace config data
//   Azure: https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/blobservices/containers
resource synapseWorkspaceStorageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${synapseStorageAccount.name}/default/workspace'
}

// Azure Data Lake Storage Gen2: Storage Container for Azure Synapse Lakehouse Sync data
//   Azure: https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/blobservices/containers
resource synapseSyncStorageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${synapseStorageAccount.name}/default/synapsesync'
}

// Azure Data Lake Storage Gen2: Storage Account that acts as our Enterprise Data Lake
//   Azure: https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts
resource enterpriseDataLakeStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: 'enterprisedatalake${resourceSuffix}'
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
    }
    publicNetworkAccess: 'Enabled'
  }
}

// Azure Data Lake Storage Gen2: Storage Container for the Enterprise Data Lake Gold Zone
//   Azure: https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/blobservices/containers
resource enterprieDataLakeGoldStorageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${enterpriseDataLakeStorageAccount.name}/default/gold'
}

output synapseStorageAccountName string = synapseStorageAccount.name
