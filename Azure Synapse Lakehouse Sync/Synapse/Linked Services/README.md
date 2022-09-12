# Synapse Analytics Workspace Linked Services

The following Linked Services should be imported into your Synapse Analytics Workspace. **LS_AzureDatabricks_Managed_Identity** and **LS_Synapse_Managed_Identity** will need to be imported first and are both referenced by the Azure Synapse Lakehouse Sync pipelines.

## LS_AzureDatabricks_Managed_Identity.json

**Required:** YES

This Linked Service uses Managed Identity to authenticate to Databricks. You can create a new Linked Service for Databricks using Managed Identity but be sure to name it **LS_AzureDatabricks_Managed_Identity**. If you import this Linked Service, the below JSON values need to be updated to reflect your Databricks Workspace.

```
{
    "properties": {
        "typeProperties": {
            "domain": "REPLACE_DATABRICKS_WORKSPACE_URL",
            "workspaceResourceId": "REPLACE_DATABRICKS_WORKSPACE_ID",
            "existingClusterId": "REPLACE_DATABRICKS_CLUSTER_ID"
        }
    }
}
```

## LS_Enterprise_Data_Lake.json

**Required:** NO

This Linked Service is used in the Tutorial Environment to connect the Azure Data Lake Storage Account to the Synapse Analytics Workspace. It's not referenced by any pipeline and is not required for Azure Synapse Lakehouse Sync self-deployment.

## LS_Synapse_Managed_Identity.json

**Required:** YES

This Linked Service uses Managed Identity to authenticate to the Synapse Dedicated SQL Pool. It's referenced by the **DS_Synapse_Managed_Identity** Dataset which is then referenced by the Azure Synapse Lakehouse Sync pipelines.

There are no values in the JSON that need to be modified.