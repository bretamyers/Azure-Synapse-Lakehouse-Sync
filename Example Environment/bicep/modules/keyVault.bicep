/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Key Vault
//
//       Key Vault for storing Azure Data Lake Storage Gen2 credentials.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

targetScope = 'resourceGroup'

param azureRegion string
param resourceSuffix string

// Reference to the Storage Account we created
resource synapseStorageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  name: 'synapsesync${resourceSuffix}'
}

// Key Vault
//   Azure: https://docs.microsoft.com/en-us/azure/key-vault/general/quick-create-portal
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: 'synapsesync${resourceSuffix}'
  location: azureRegion

  properties: {
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    accessPolicies: []
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
  }
}

// Key Vault: Storage Account Key Secret
//   Azure: https://docs.microsoft.com/en-us/azure/key-vault/general/about-keys-secrets-certificates
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/secrets
resource synapseStorageAccountKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'DataLakeStorageKey'
  parent: keyVault
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'string'
    value: synapseStorageAccount.listKeys().keys[0].value
  }
}

output keyVaultVaultUri string = keyVault.properties.vaultUri
output keyVaultId string = keyVault.id
