## Synapse_Lakehouse_Sync_Metadata.csv

**Required for Self-Deployment:** YES

This file instructs Azure Synapse Lakehouse Sync on what source Delta tables should be synchronized to the Synapse Dedicated SQL Pool and is referenced by the **SynapseLakehouseSync** pipeline using the **StorageAccountNameMetadata** parameter. It should be updated to reflect your environment and located within the Synapse Workspace storage account container that contains the change data. 

If you deploy the Tutorial Environment this file will be automatically copied to the **synapsesync** storage account container and updated to reflect the environment.

### CSV Structure

Column Name | Description
---|---
PoolName | Name of the Synapse Dedicated SQL Pool to synchronize the Delta tables to. Example: _DataWarehouse_
SchemaName | Schema name to use for the tables in Synapse Dedicated SQL. Example: _AdventureWorks_
TableName | Name of the individual table. Example: _FactInternetSales_
KeyColumns | Unique Key/Identity column in the _TableName_ used by Azure Synapse Lakehouse Sync for synchronization purposes. Example: __Id_
DeltaDataADLSFullPath | Full Azure Data Lake ABFS path of the Delta table which should be synchronized. Example: _abfss://gold@myenterprisedatalake.dfs.core.windows.net/Sample/AdventureWorks/FactInternetSales/_
DeltaDataDatabricksKeyVaultScope | Name of the Databricks Secret Scope that references your Azure Key Vault. Example: _EnterpriseDataLakeKeyVaultScope_
DeltaDataAzureKeyVaultSecretName | Key Vault Secret Name that contains the Azure Data Lake Storage Account Key for where the source Delta table is located. Example: _EnterpriseDataLakeAccountKey_
SynapseSyncDataADLSFullPath | Full Azure Data Lake ABFS path of the location where Azure Synapse Lakehouse Sync should store the Delta change data. This can be a seperate storage account from the source Delta table. It's probably best to store this in the Azure Data Lake Storage Account thats attached to the Synapse Workspace for organization purposes, but it can technically be stored anywhere. Example: _abfss://synapsesync@mysynapseworkspacestorage.dfs.core.windows.net/_
SynapseSyncDataDatabricksKeyVaultScope | Name of the Databricks Secret Scope that references your Azure Key Vault. Example: _SynapseSyncKeyVaultScope_
SynapseSyncDataAzureKeyVaultSecretName | Key Vault Secret Name that contains the Azure Data Lake Storage Account Key for where the Delta table change data is located. Example: _SynapseStorageAccountKey_


## FAQ

### Is this metadata CSV file required for self-deploying in my own environment?
Yes. This file is used by the **SynapseLakehouseSync** pipeline in the Synapse Analytics Workspace. You must update this file to reflect your environment and ensure the **SynapseLakehouseSync** pipeline has the **StorageAccountNameMetadata** parameter set to the correct location.

### Do I need to populate KeyColumns?
Yes. Azure Synapse Lakehouse Sync uses this column to efficiently synchronize the Synapse Dedicated SQL tables with the Delta table changes. Your Delta tables must be updated to include this column. An example can be found within the **Convert Parquet to Delta TAbles - AdventureWorks** Databricks Notebook contained within this repository.

### Why are there two Databricks Secure Scopes for Azure Key Vault?
We did this since your central data lake(s) are likely managed separate from Azure Synapse and Azure Synapse Lakehouse Sync. It allows you to reference one Azure Key Vault for your central data lake, and another Azure Key Vault for the Azure Synapse Lakehouse Sync change data storage.

### Can I use the same Azure Key Vault for both Databricks Secure Scopes?
Yes. We allow you to specify two Azure Key Vaults for flexibility in complex production environments, but you can use only one Azure Key Vault. You will still have to Databricks Secure Scopes but they reference the same Azure Key Vault. The Tutorial Environment is an example of using two Databricks Secure Scopes that reference a single Azure Key Vault. 

### Can DeltaDataADLSFullPath and SynapseSyncDataADLSFullPath be on the same Azure Data Lake Storage Account?
Yes. While the source Delta tables and Synapse Sync change data can coexist on the same storage account, it will likely offer better organization to store the data separate. The Tutorial Environment is an example of using two Azure Data Lake Storage Accounts. By using two, it allows any Azure Synapse Lakehouse Sync instances to be self-contained. While Azure Synapse Lakehouse Sync will read Delta tables on the central data lake, the configuration and change data will be contained entirely within the Azure Synapse environment.
