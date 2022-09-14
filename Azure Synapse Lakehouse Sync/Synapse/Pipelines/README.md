# Synapse Analytics Workspace Pipelines

The following pipelines should be imported into your Synapse Analytics Workspace. They're listed in the order they must be imported since they reference one another. The actual name of the pipelines do not, and should not contain the number prefix.

## 01 - SynapseLakehouseSyncTableLoad.json

**Required for Self-Deployment:** YES

This pipeline is called from the **SynapseLakehouseSync** pipeline and should not be modified. It's responsible for the second half of the Azure Synapse Lakehouse Sync process which is importing the Delta table changes into Synapse Dedicated SQL.

## 02 - SynapseLakehouseSync.json

**Required for Self-Deployment:** YES

This is the primary pipeline for Azure Synapse Lakehouse Sync. It's responsible for executing the Databricks Notebooks which capture the changed data from the Delta tables. It should be scheduled to execute at whatever interval makes sense for your data lake Delta tables to be synchronized to Synapse Dedicated SQL.

The **StorageAccountNameMetadata** parameter is the only change that should be made to this pipeline when self-deploying.

### Parameters

Parameter Name | Description
---|---
StorageAccountNameMetadata | The full path of the Synapse_Lakehouse_Sync_Metadata.csv file which should be located on the Synapse Workspace Data Lake Storage Account. Example: https://mysynapseworkspacestorage.dfs.core.windows.net/synapsesync/Synapse_Lakehouse_Sync_Metadata.csv

### Variables (DO NOT MODIFY)
These variables should not be modified but we're documenting their use.

Variable Name | Description
---|---
DatabricksOutputArray | Output from the **Synapse Lakehouse Sync ADLS** Databricks Notebook. It's used by the pipeline to identify what changes types have occurred (full_load or incremental) and used for logging purposes.
PipelineValues | Used for storing runtime values in the pipeline such as the execution date and time.
MetadataArray | Used for determining what tables exist at runtime.
DropTableFlag | If the DropTableFlag parameter is true, then drop the Synapse Dedicated SQL staging tables that are created during the loading process after the data has been loaded. This will keep the Synapse Dedicated SQL Pool clean.


## 03 - SynapseLakehouseSync_Tutorial.json

**Required for Self-Deployment:** NO

This pipeline is used only for the Tutorial Environment. When executed, it demonstrates:
- Converting the standard parquet sample data to Delta 2.0 using the **Convert Parquet to Delta Tables - AdventureWorks** Databricks Notebook.
- Adding the **_Id** identity column to the new Delta tables using the **Convert Parquet to Delta Tables - AdventureWorks** Databricks Notebook.
- Doing an initial full import from Delta to Synapse Dedicated SQL using the **SynapseLakehouseSync** pipeline.
- Simulates inserts/updates/deletes to the source Delta tables using the **Simulate Data Changes - AdventureWorks** Databricks Notebook.
- Does the Delta change synchronization to Synapse Dedicated SQL using the **SynapseLakehouseSync** pipeline.
