# Databricks Notebooks: Synapse Lakehouse Sync

The following Databricks Notebooks are the core logic of Azure Synapse Lakehouse Sync and are all required for self-deployment. All Notebook execution is executed by the Azure Synapse Workspace pipeline.

## Synapse Lakehouse Sync ADLS.dbc

**Required for Self-Deployment:** YES

This is the primary Notebook for Azure Synapse Lakehouse Sync and contains the core synchronization logic. It will output a parquet formatted dataset with the changed Delta table data, partitioned by the change type (deletes, inserts, updates). The output from this Notebook will be synchronized to the Synapse Dedicated SQL Pool.

## Synapse Lakehouse Sync Create Tracking Table.dbc

**Required for Self-Deployment:** Yes

This Notebook creates the _SynapseLakehouseSyncTracker Delta table for tracking synchronization history.

## Synapse Lakehouse Sync Functions.dbc

**Required for Self-Deployment:** Yes

Contains functions used throughout the other Notebooks.

## Synapse Lakehouse Sync Tracking Table Log Success.dbc

**Required for Self-Deployment:** Yes

This Notebook calls the ClosedEntry() function which updates the _SynapseLakehouseSyncTracker table with statistics upon a successful synchronization.

## Synapse Lakehouse Sync Tracking Table Optimize.dbc

**Required for Self-Deployment:** Yes

This Notebook will optimize and vacuum the _SynapseLakehouseSyncTracker table to remove and compact the files for optimal reading performance on the next synchronization.