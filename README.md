# Azure-Synapse-Lakehouse-Sync

Prerequisites:
	Synapse Workspace with the sync solution artifacts added (pipelines and linked services)
	Synapse dedicated pool created and running
	Databricks workspace with notebooks added
	Storage account with data preferably structured in a dimensional model

Inputs:
	PoolName - The Synapse dedicated pool name
	DatabaseName - The Synapse tables schema name
	TableName - The Synapse table name
	FolderPathFull - The full path to the ADLS location for the data in delta format
	ChangesFolderPathFull - The full path for the ADLS location where the change feed files will land.

Example
	myPool
	,schemaA
	,tableA
	,abfss://goldzone@myadlsstorage.dfs.core.windows.net/myDB/schemaA/tableA
	,abfss://synapselakehousesync@myadlsstorage.dfs.core.windows.net/

Note - in the above example, the change feed files will be stored here abfss://synapselakehousesync@myadlsstorage.dfs.core.windows.net/myPool_SynapseLakehouseSync/schemaA/tableA/{change folders}
	A separate folder location in delta format is created and used to track what data has been sync'd to Synapse. abfss://synapselakehousesync@myadlsstorage.dfs.core.windows.net/myPool_SynapseLakehouseSync/_SynapseLakehouseSyncTracker

The sync solution is self contained and is self healing. No artifacts need to exist in the Synapse dedicated pool.

