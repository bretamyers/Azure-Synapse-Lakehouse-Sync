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
param synapseAzureADAdminObjectId string

// Reference to the Synapse Workspace Storage Account we created
resource synapseStorageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  name: 'synapsesync${resourceSuffix}'
}

// Reference to the Enterprise Data Lake Storage Account we created
resource enterpriseDataLakeStorageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  name: 'enterprisedatalake${resourceSuffix}'
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

// Key Vault: Access Policy
//   Azure: https://docs.microsoft.com/en-us/azure/key-vault/general/assign-access-policy
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/accesspolicies
resource keyVaultPermissions 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        objectId: synapseAzureADAdminObjectId
        permissions: {
          secrets: [ 
            'get'
            'list'
            'set'
            'delete'
          ]
        }
        tenantId: subscription().tenantId
      }
    ]
  }
}


// Key Vault: Synapse Workspace Storage Account Key Secret
//   Azure: https://docs.microsoft.com/en-us/azure/key-vault/general/about-keys-secrets-certificates
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/secrets
resource synapseStorageAccountKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'SynapseStorageAccountKey'
  parent: keyVault
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'string'
    value: synapseStorageAccount.listKeys().keys[0].value
  }
}

// Key Vault: Enterprise Data Lake Storage Account Key Secret
//   Azure: https://docs.microsoft.com/en-us/azure/key-vault/general/about-keys-secrets-certificates
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/secrets
resource enterpriseDataLakeAccountKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'EnterpriseDataLakeAccountKey'
  parent: keyVault
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'string'
    value: enterpriseDataLakeStorageAccount.listKeys().keys[0].value
  }
}

output keyVaultName string = keyVault.name
output keyVaultVaultUri string = keyVault.properties.vaultUri
output keyVaultId string = keyVault.id
