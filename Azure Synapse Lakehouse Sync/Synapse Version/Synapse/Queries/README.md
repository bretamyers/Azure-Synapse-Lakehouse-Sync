# Synapse Dedicated SQL Queries

## Create_Resource_Class_Users.sql

**Required for Self-Deployment:** YES

If self-deploying you must execute these queries on your Synapse Dedicated SQL Pool. These Resource Classes are used by the Azure Synapse Lakehouse Sync pipelines to efficiently synchronize the change data.

## Enable_Query_Store.sql

**Required for Self-Deployment:** NO

While not required by Azure Synapse Lakehouse Sync, it is good practice to enable the [Query Store](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql/query-history-storage-analysis) on your Synapse Dedicated SQL Pool. We enable the Query Store by default in the Tutorial Environment.
