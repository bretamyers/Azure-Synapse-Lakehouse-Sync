# Databricks Notebooks: Synapse Lakehouse Sync Tutorial

The following Databricks Notebooks are part of the Tutorial Environment. They are executed by the **SynapseLakehouseSync_Tutorial** pipeline in the Synapse Analytics Workspace. While you don't need to execute these directly, the **Convert Parquet to Delta Tables - AdventureWorks** Notebook does provide an example of converting parquet files to Delta 2.x, along with adding the **_Id** identity column required by Azure Synapse Lakehouse Sync.

## Convert Parquet to Delta Tables - AdventureWorks.dbc

**Required for Self-Deployment:** NO

This Notebook provides examples that satisfy two requirement of Azure Synapse Lakehouse Sync; 1) Delta 2.x tables, and 2) having an identity column in each table.

### Converting Parquet to Delta 2.x Tables
Demonstrates taking several standard parquet tables and converting them to Delta 2.x, which should be considered our Gold Zone. The Delta 2.x tables are created using the Change Data Feed feature, enabled by setting TBLPROPERTIES (delta.enableChangeDataFeed = true) at the table level. Change Data Feed must be enabled for all tables that are synchronized to Synapse Dedicated SQL.

### Adding an _Id Identity Column
An _Id identity column is added to each table with the following syntax BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1). While not technically required, adding the _Id identity column makes the synchronization process to Synapse Dedicated SQL simpiler and faster.

## Simulate Data Changes - AdventureWorks.dbc

**Required for Self-Deployment:** NO

This Notebook performs synthentic create/update/delete operations on the sample tables. The purpose is to demonstrate how ongoing changes are performed, captured, and synchronized by Azure Synapse Lakehouse Sync.
