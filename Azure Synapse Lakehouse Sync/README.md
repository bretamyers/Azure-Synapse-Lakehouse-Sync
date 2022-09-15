# Azure Synapse Lakehouse Sync: Self Deployment


## Self Deployment: Getting Started
#### Prerequisites
- Synapse Workspace with the sync solution artifacts added (pipelines and linked services)
- Synapse dedicated pool created and running
- Databricks workspace with notebooks added
- Storage account with data preferably structured in a dimensional model

#### Inputs
- PoolName - The Synapse dedicated pool name
- DatabaseName - The Synapse tables schema name
- TableName - The Synapse table name
- FolderPathFull - The full path to the ADLS location for the data in delta format
- ChangesFolderPathFull - The full path for the ADLS location where the change feed files will land.

#### Example
- PoolName = myPool 
- DatabaseName  = schemaA
- TableName = tableA
- FolderPathFull = abfss://goldzone@myadlsstorage.dfs.core.windows.net/myDB/schemaA/tableA
- ChangesFolderPathFull = abfss://synapselakehousesync@myadlsstorage.dfs.core.windows.net/
	
Note - in the above example, the change feed files will be stored here abfss://synapselakehousesync@myadlsstorage.dfs.core.windows.net/myPool_SynapseLakehouseSync/schemaA/tableA/{change folders}
	A separate folder location in delta format is created and used to track what data has been sync'd to Synapse. abfss://synapselakehousesync@myadlsstorage.dfs.core.windows.net/myPool_SynapseLakehouseSync/_SynapseLakehouseSyncTracker

The sync solution is self contained and is self healing. No artifacts need to exist in the Synapse dedicated pool.


### Features
- Create 

### Helper Scripts
- **Convert Parquet to Delta Tables** - An example spark notebook on how to recreate your existing parquet table on ADLS to a delta table with the \[_Id\] column added. 

### Sync Benchmarks

Initial benchmarks shows that using the _Id column created using the gnereate always as identity, produces 30-60% faster loads.


### Loading Process
1.	The Synapse Lakehouse Sync pipeline first reads a csv file that is in the format of the example metadata file. You provide the ADLS full path location of the csv file as a parameter to the pipeline.
2.	It then will query the pool names specified in the metadata csv file to determine what schemas and tables exist in the pool. 
3.	We then create any schemas in the pool that were specified in the metatdata file but did not exist in the pool.
4.	An Azure Databricks notebook is then executed that utilizes the delta 2.0 change feed feature to stage inserts, updates, and deletes on each table into the SyncFolderPathFull destination that was supplied in the metadata. The data is landed in the following naming convention:
{SyncFolderPath}/{PoolName}_SynapseLakehouseSync/{DatabaseName}/{TableName}
A full load will occur if the table was not found in the pool or the Synapse Lakehouse Sync table does not contain an entry for that pool, database, and table combination. A full load pull the latest version of all the data from the delta table and drop if exists, create, and load the table in the dedicated pool apply the smallest datatypes possible given the data that is being loaded. It also take a best guess on table distribution and index based off of the profile of the data being loaded.
If the table exists in the pool and there is data for that pool, database, and table combination in the sync tracking table, we then do an incremental load. An incremental load uses the delta change feed functionality to pull the latest version per change type (insert, update, delete) and place these records onto ADLS into separate directories in parquet format.
5.	The data is then loaded from the change folders into the pool as staging tables (round_robin heaps) with the following naming convention {DatabaseName}.{TableName}_{ChangeType}.
6.	Once staged, we then dynamically construct the delete, insert, and update statements and execute them in that order against the final table.
7.	If the statements are successful, we then update the log entry in the tracking table.
8.	Lastly, the pipeline will then run the vacuum and optimize commands on the Synapse Lakehouse Sync tracking delta table.


#### Non-compatible Column Data Types
- ArrayType
- MapType
- Nested StructType



#### Synaple Lakehouse Sync Metadata File
Column Name | Description
-|-
PoolName | The name of the target Synapse   dedicated pool
SchemaName | The schema for the table in the   Synapse dedicated pool
TableName | The table name for the table in   Synapse dedicated pool
KeyColumns | The column or columns (comma   separated) that make a row unique in the source table
DataFolderPathFull | The full path in either https   or abfss to the folder containing the delta files
SyncFolderPathFull | The full path in either https   or abfss to the folder that will contain the Synapse lakehouse sync tracking   table and change files. It is recommended to use a separate   filesystem/container in the storage account of the data.

## Logging Tables
#### Synapse Dedicated SQL: logging.DataProfile

This table is used to store the data profiling results of each column in a table. Only full loads will result in data to be profiled and logged into this table.

Column Name | Description
-|-
Id | Identity column of the table 
PipelineRunId | The Synapse pipeline run guid
PipelineStartDate | The Synapse pipeline run start date as an int in yyyyMMdd format
PipelineStartDateTime | The Synapse pipeline run start date as a datetype
SchemaName | The schema of the table
TableName | The table name
ColumnName | The column name
DataTypeName | The datatype of the column
DataTypeFull | The detailed datatype of the column with precision and scale
CharacterLength | The max character length of the column
PrecisionValue | The precision of the column applicable 
ScaleValue | The scale of the column if applicable
UniqueValueCount | The number of unique values found for that column
NullCount | The number of null values found for that column
MinValue | The min data value for the column
MaxValue | The max data value for the column
MinLength | The min length of the column
MaxLength | The max length of the column
DataAverage | The average value of the data in the column if applicable
DataStdevp | The standard deviation of the data in the column if applicable
TableRowCount | The total row count for the table
TableDataSpaceGB | The disk space in GB of the staged data. RR heap.
WeightedScore | The columns score value for determining if it is a good candidate or not for a hash distribution. The weighting logic if based off of multiple factors like data type, data type length, number of null values, table row count, and unique value count to come up with good candidates for the distribution and index of the table.
SqlCommandDataProfile | The t-sql to generate the values in the logging.DataProfile table for the rows table.
SqlCommandCTAS | The t-sql to create table as select (CTAS) into a new table with “{tableName}_{columnName}” as the table name with the column of the row as the hash distribution. The DROP original and RENAME new to original syntax is also included. The loading process will do a best guess on multiple conditions to pick the best distribution and index. What is picked may not be the most optimal based off of the query patterns of the users. This column provides the syntax to easily recreate the table with a different distribution and index.
RowInsertDateTime | The datetime the record was inserted into the table.


#### Synapse Dedicated SQL: logging.SynapseLakehouseSync
Contains the record counts of both the data in the source Delta table but also the record counts in the target Synapse Dedicated SQL table.

Column Name | Description
-|-
Id | Identity column of the table
PoolName | The Synapse dedicated pool name
SchemaName | The Synapse schema name of the table
TableName | The Synapse table name
TableRowCountADLS | The total row count for the data in the source delta table on ADLS
TableRowCountSynapse | The total row count of the table that is in Synapse
RowInsertDateTime | The datetime the record was inserted into the table

#### Azure Synapse Lakehouse Sync ADLS Change Table: _SynapseLakehouseSyncTracker
A delta table that is created in the specified SyncFolderPathFull value from Synapse Lakehouse Sync loading metadata file. The table is used throughout the solution to track the sync's loading progress and to identify what versions of the table have already been synchronized to Synapse Dedicated SQL.

Column Name | Description
-|-
SynapseLakehouseSyncKey | A hashed (md5) value of the pool name, database name, table name, and the insert date time columns.
PoolName | The target Synapse Dedicated SQL Pool
SchemaName | The target Synapse tables schema name
TableName | The target Synapse table name
VersionNumberStart | The delta version number used as the start for the change data feed
VersionNumberEnd | The delta version number used as the end for the change data feed
DateTimeStart | The datetime start in association of the version number start
DateTimeEnd | The datetime end in association of the version number end
InsertDateTime | The insert datetime of the   record
LoadType | The load type to occur. Either “Full Load” or “Incremental”
ChangeTypes | The change type(s) to occur. It will be either “full_load” or a combination of “insert”, “delete”, and “update”. Full_load – all of the data from the delta table is staged into ADLS to be loaded into Synapse. Insert – Records identified to be inserted into the Synapse table Update - Records identified to   be updated into the Synapse table Delete - Records identified to be deleted into the Synapse table 
TableRowCountADLS | The total row count for the data in the source delta table on ADLS
TableRowCountSynapse | The total row count of the table that is in Synapse
ADLSStagedFlag | A flag for identifying when the data from the changed data feed has been queried and staged into ADLS.
SynapseLoadedFlag | A flag for identifying when the data was successfully loaded into Synapse. No pipeline errors occurred.
SynapseLoadedDateTime | The datetime of when the data was loaded into Synapse with no errors.