/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Databricks Workspace
//
//       Create the Databricks Workspace.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

targetScope = 'resourceGroup'

param azureRegion string
param resourceSuffix string

// Azure Databricks: Workspace
//   Azure: https://docs.microsoft.com/en-us/azure/databricks/scenarios/quickstart-create-databricks-workspace-portal
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.databricks/workspaces
resource databricksWorkspace 'Microsoft.Databricks/workspaces@2021-04-01-preview' = {
  name: 'synapsesync${resourceSuffix}'
  location: azureRegion

  sku: {
    name: 'premium'
  }
  properties: {
    managedResourceGroupId: subscriptionResourceId('Microsoft.Resources/resourceGroups', 'databricks-rg-synapsesync${resourceSuffix}')
  }
}

output databricksWorkspaceName string = databricksWorkspace.name
