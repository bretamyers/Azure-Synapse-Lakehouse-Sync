/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Synapse Analytics Workspace
//
//       Create the Synapse Analytics Workspace along with a DWU1000 Dedicated SQL Pool for the Data Warehouse.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

targetScope = 'resourceGroup'

param resourceSuffix string
param azureRegion string
param synapseSQLPoolName string
param synapseSQLAdministratorLogin string
@secure()
param synapseSQLAdministratorLoginPassword string
param synapseAzureADAdminObjectId string

// Reference to the Storage Account we created
resource synapseStorageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  name: 'synapsesync${resourceSuffix}'
}

// Synapse Workspace
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/overview-what-is
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces
resource synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: 'synapsesync${resourceSuffix}'
  location: azureRegion
  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    //publicNetworkAccess: (enable_private_endpoints) ? 'Disabled' : 'Enabled'
    managedVirtualNetwork: 'default'
    defaultDataLakeStorage: {
      accountUrl: synapseStorageAccount.properties.primaryEndpoints.dfs
      filesystem: 'config'
    }
    sqlAdministratorLogin: synapseSQLAdministratorLogin
    sqlAdministratorLoginPassword: synapseSQLAdministratorLoginPassword
  }
}

// Azure Data Lake Storage Gen2 Permissions: Give the Synapse Analytics Workspace Managed Identity permissions to Azure Data Lake Storage Gen2
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/security/how-to-grant-workspace-managed-identity-permissions
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/Microsoft.Authorization/roleAssignments
resource synapseStorageWorkspacePermissions 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(synapseWorkspace.id, subscription().subscriptionId, 'Contributor')
  scope: synapseStorageAccount
  properties: {
    principalId: synapseWorkspace.identity.principalId
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  }
}

// Azure Data Lake Storage Gen2 Permissions: Give the Synapse Analytics Azure AD Admin user permissions to Azure Data Lake Storage Gen2
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/security/how-to-grant-workspace-managed-identity-permissions
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/Microsoft.Authorization/roleAssignments
resource synapseStorageAzureADAdminPermissions 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(synapseWorkspace.id, synapseAzureADAdminObjectId, 'Contributor')
  scope: synapseStorageAccount
  properties: {
    principalId: synapseAzureADAdminObjectId
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  }
}

// Synapse Dedicated SQL Pool: Create the initial SQL Pool for the Data Warehouse
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/quickstart-create-sql-pool-studio
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces/sqlpools
resource synapseSQLPool 'Microsoft.Synapse/workspaces/sqlPools@2021-06-01' = {
  name: synapseSQLPoolName
  parent: synapseWorkspace
  location: azureRegion
  sku: {
    name: 'DW100c'
  }
}

// Synapse Dedicated SQL Pool Geo-Backups: Disable Geo-Backups
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/backup-and-restore
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces/sqlpools/geobackuppolicies
resource synapseSQLPoolGeoBackups 'Microsoft.Synapse/workspaces/sqlPools/geoBackupPolicies@2021-06-01' = {
  name: 'Default'
  parent: synapseSQLPool
  properties: {
    state: 'Disabled'
  }
}

// Synapse Workspace Firewall: Allow authenticated access from anywhere
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/security/synapse-workspace-ip-firewall
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces/firewallrules
resource synapseFirewallAllowAzureServices 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = {
  name: '${synapseWorkspace.name}/AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

// Synapse Workspace Firewall: Allow authenticated access from anywhere
//   Azure: https://docs.microsoft.com/en-us/azure/synapse-analytics/security/synapse-workspace-ip-firewall
//   Bicep: https://docs.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces/firewallrules
resource synapseFirewallAllowAll 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = {
  name: '${synapseWorkspace.name}/AllowAll'
  properties: {
    endIpAddress: '255.255.255.255'
    startIpAddress: '0.0.0.0'
  }
}

output synapseAnalyticsWorkspaceName string = synapseWorkspace.name
