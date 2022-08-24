/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Azure Synapse Lakehouse Sync: Bicep Template
//
//    Deploy via Azure Cloud Shell (https://shell.azure.com):
//      az deployment sub create --template-file Bicep/main.bicep --parameters Bicep/main.parameters.json --name Azure-Synapse-Lakehouse-Sync --location eastus
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

targetScope='subscription'

@description('Region to create all the resources in.')
param azureRegion string

@description('Resource Group for all related Azure services.')
param resourceGroupName string

@description('Name of the SQL pool to create.')
param synapseSQLPoolName string

@description('Native SQL account for administration.')
param synapseSQLAdministratorLogin string

@description('Password for the native SQL admin account above.')
@secure()
param synapseSQLAdministratorLoginPassword string

@description('Object ID (GUID) for the Azure AD administrator of Synapse. This can also be a group, but only one value can be specified. (i.e. XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXXXXXXX). "az ad user show --id "sochotny@microsoft.com" --query id --output tsv"')
param synapseAzureADAdminObjectId string

// Add a random suffix to ensure global uniqueness among the resources created
//   Bicep: https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-string#uniquestring
var resourceSuffix = substring(uniqueString(subscription().subscriptionId, deployment().name), 0, 3)

// Create the Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: resourceGroupName
  location: azureRegion
  tags: {
    Environment: 'PoC'
    Application: 'Azure Synapse Analytics'
    Purpose: 'Azure Synapse Lakehouse Sync'
  }
}

// Create the Azure Data Lake Storage Gen2 Account
module synapseStorageAccount 'modules/storageAccount.bicep' = {
  name: 'storageAccount'
  scope: resourceGroup
  params: {
    resourceSuffix: resourceSuffix
    azureRegion: azureRegion
  }
}

// Create the Synapse Analytics Workspace
module synapseAnalytics 'modules/synapseAnalytics.bicep' = {
  name: 'synapseAnalytics'
  scope: resourceGroup
  params: {
    resourceSuffix: resourceSuffix
    azureRegion: azureRegion
    synapseSQLPoolName: synapseSQLPoolName
    synapseSQLAdministratorLogin: synapseSQLAdministratorLogin
    synapseSQLAdministratorLoginPassword: synapseSQLAdministratorLoginPassword
    synapseAzureADAdminObjectId: synapseAzureADAdminObjectId
  }

  dependsOn: [
    synapseStorageAccount
  ]
}

// Create the Databricks Workspace
module databricksWorkspace 'modules/databricksWorkspace.bicep' = {
  name: 'databricksWorkspace'
  scope: resourceGroup
  params: {
    resourceSuffix: resourceSuffix
    azureRegion: azureRegion
  }

  dependsOn: [
    synapseStorageAccount
  ]
}

// Outputs for reference in the deploySynapseSync.sh Post-Deployment Configuration
output synapseAnalyticsWorkspaceName string = synapseAnalytics.outputs.synapseAnalyticsWorkspaceName
output synapseSQLPoolName string = synapseSQLPoolName
output synapseSQLAdministratorLogin string = synapseSQLAdministratorLogin
output databricksWorkspaceName string = databricksWorkspace.outputs.databricksWorkspaceName
output datalakeName string = synapseStorageAccount.outputs.synapseStorageAccountName
