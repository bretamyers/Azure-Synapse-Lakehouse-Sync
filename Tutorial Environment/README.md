# Azure Synapse Lakehouse Sync: Tutorial Environment

Whether you're new to the data lake & lakehouse pattern, or exploring how Synapse Lakehouse Sync would work in your environment, this will deploy an end-to-end tutorial environment. We wanted to provide an easy option for you to evaluate and understand how Azure Synapse Lakehouse Sync works with little effort.

https://user-images.githubusercontent.com/16770830/192665633-1ecf047a-caae-44c8-b082-1580caee080c.mp4

<br>

# How to Deploy

The following commands should be executed from the Azure Cloud Shell at https://shell.azure.com using Bash. This will deploy the full tutorial environment with no additional configuration needed.

### Synapse Only Version
```
@Azure:~$ git clone https://github.com/bretamyers/Azure-Synapse-Lakehouse-Sync
@Azure:~$ cd 'Azure-Synapse-Lakehouse-Sync/Tutorial Environment'
@Azure:~$ bash deployTutorial.sh 
```

### Synapse + Databricks Version
```
@Azure:~$ git clone https://github.com/bretamyers/Azure-Synapse-Lakehouse-Sync
@Azure:~$ cd 'Azure-Synapse-Lakehouse-Sync/Tutorial Environment'
@Azure:~$ bash deployTutorial.sh no
```

<br>

# How to use the Azure Synapse Lakehouse Sync Tutorial
After the deployment of the tutorial environment through the Azure Cloud Shell has completed successfully, make note of the Synapse workspace name that was created and navigate to the Synapse Workspace by going [web.azuresynapse.net](web.azuresynapse.net) and selecting the newly deployed workspace from the drop downs.

<img src="https://user-images.githubusercontent.com/16770830/192761589-28e22df8-e236-4a9d-9a15-e180f50e53f4.png" width="600" />

Once in the Synapse workspace, navigate to the **Integrate** tab on the left menu and drill down to the **SynapseLakehouseSync_Tutorial** pipeline in the **Synapse Lakehouse Sync Tutorial** folder.

<img src="https://user-images.githubusercontent.com/14877390/192541566-7b4a0ffa-13f9-4bf3-8607-f175f514de7b.png" width="600" />
<img src="https://user-images.githubusercontent.com/14877390/192542004-d036d872-d2b7-4834-ac98-24af7e75a2b3.png" width="600" />

In the **SynapseLakehouseSync_Tutorial** pipeline, click on the **Add trigger** button in the top toolbar and select **Trigger now**. Select **OK** in the dialog to trigger the execution of the tutorial pipeline.

<img src="https://user-images.githubusercontent.com/14877390/192295875-d731ed9c-1ce1-43f8-8bc9-c187ca60448b.png" width="600" />
<img src="https://user-images.githubusercontent.com/14877390/192296498-197f406b-c144-4bfe-a848-2f2ac3cea9cc.png" width="400" />

<br>

# Tutorial Pipeline Steps
The **SynapeLakehouseSync_Tutorial** pipeline is designed to simulate data loads that occur in the Gold Zone on the data lake and synchronize those changes to two Synapse Dedicated SQL Pools. 

<img src="https://user-images.githubusercontent.com/16770830/192806174-8f1481f0-63d9-4f34-9533-9bcf72adca54.png" />

1. First, we drop any existing tables from the Synapse Dedicated SQL Pools. This allows consistent repeatability when rerunning the **SynapeLakehouseSync_Tutorial** pipeline.
1. Next we run the **Convert Parquet to Delta Tables - AdventureWorks** Databricks notebook. This tutorial notebook converts the sample Gold Zone parquet dataset (AdventureWorks_parquet) provided in the deployment to Delta 2. This conversion does two primary things:

   - The Delta 2.0 tables are created using the [Change Data Feed](https://docs.delta.io/2.0.0rc1/delta-change-data-feed.html) feature, enabled by setting ```TBLPROPERTIES (delta.enableChangeDataFeed = true)``` at the table level. Change Data Feed must be enabled for all tables that are synchronized to Synapse Dedicated SQL.
   - An **_Id** identity column is added to each table with the following syntax ```BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1)```. Adding the **_Id** identity column makes the synchronization process to Synapse Dedicated SQL simpiler and faster.

1. After the Delta 2 tables are created in the Gold Zone, we execute the primary **SynapseLakehouseSync** pipeline to start the synchronization process. The **SynapseLakehouseSync** pipeline reads the provided [Synapse_Lakehouse_Sync_Metadata.csv](https://github.com/bretamyers/Azure-Synapse-Lakehouse-Sync/tree/main/Azure%20Synapse%20Lakehouse%20Sync/Synapse#csv-structure) metadata file to understand what tables should be synchronized. Because none of the tables exist exist in Synapse Dedicated SQL, a full load will be triggered. 

   You'll notice the sample metadata file contains two separate Synapse Dedicated SQL Pools. This demonstrates synchronizating all tables, and a subset of tables, to different Synapse Dedicated SQL Pools.

   ![image](https://user-images.githubusercontent.com/14877390/192312295-2f752a32-9f7c-4d89-8959-eae508e6d702.png)

1. Once the full load of all tables to the Synapse Dedicated SQL Pools have completed, we then run the **Simulate Data Changes - AdventureWorks**  Databricks notebook. This notebook simulates data changes to the underlying Delta 2 tables. The changes include updates, inserts, deletes, and data type length changes.

1. We execute the primary **SynapseLakehouseSync** pipeline to start the synchronization process again. Since the tables already exist in the Synapse Dedicated SQL Pools, an incremental load is triggered. It will extract the changed data from the Delta 2 Gold Zone tables and stage them in the Synapse storage account **synapsesync** container. It will then execute separate insert, update, and delete statements on the Dedicated SQL Pools to synchronize the tables.

1. Now that we've executed two synchronization processes, we run two lookup activities to check the row counts for each table. The **logging.SynapseLakehouseSync** table in each Dedicated SQL Pool contains row counts for the Delta 2 Gold Zone tables, along with the Synapse Dedicated SQL Pool tables. The **Diff** output in the lookup activity results should be 0, indicating the table record counts are the same and therefore synchronized.

1. The pipeline pauses for 10 seconds using a wait activity.

1. We now execute the **SynapseLakehouseSync** pipeline for a third time. This execution will not load any new data to Synapse Dedicated SQL since no data changes have occurred on the Delta 2 Gold Zone tables.

8. Lastly, we run the two lookup activities again to verify that no data was synchronized, and that the row counts for the tables remain the same.

<br>

# Synapse Only Version
## What's Deployed

#### Azure Synapse Analytics Workspace
- **DW1000 Dedicated SQL Pool:** Primary data warehouse Enterprise Data Lake Gold Zone changes are synchronized to
- **DW100 Dedicated SQL Pool:** Example of a second data warehouse where only some tables are synchronized from the same Enterprise Data Lake Gold Zone
- Azure Synapse Lakehouse Sync Pipelines
- **Spark Pool:** A spark pool that is used to perform the sync process capturing the delta change feed rows and simulating the records changes in the gold zone on the lake.

> NOTE: Two Synapse Dedicatd SQL Pools are created and running upon deployment. If you wish to pause the Dedicated SQL Pools to avoid charges, follow the steps [here](https://learn.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/pause-and-resume-compute-portal).


#### Azure Data Lake Storage Gen2: Synapse Workspace
- **workspace:** Container for the Azure Synapse Analytics Workspace
- **synapsesync:** Container for Azure Synapse Lakehouse Sync change history from the Enterprise Data Lake Gold Zone. It also contains the **Synapse_Lakehouse_Sync_Metadata.csv** file which instructs Azure Synapse Lakehouse Sync on the tables that need to be synchronized.

#### Azure Data Lake Storage Gen2: Enterprise Data Lake
- **gold:** Container for the Enterprise Data Lake Gold Zone which includes the sample data

# What's Configured
The **deployTutorial.sh** script will execute a Bicep deployment for the environment and then configure the environment with the Azure Synapse Lakehouse Sync artifacts including: 

- Synapse Workspace Pipelines
- Synapse Workspace Linked Services
- Synapse Workspace Datasets
- Synapse Dedicated SQL Pool
- Synapse Spark Pool
- Sample Data

<br>

# Synapse + Databricks Version
## What's Deployed

#### Azure Synapse Analytics Workspace
- **DW1000 Dedicated SQL Pool:** Primary data warehouse Enterprise Data Lake Gold Zone changes are synchronized to
- **DW100 Dedicated SQL Pool:** Example of a second data warehouse where only some tables are synchronized from the same Enterprise Data Lake Gold Zone
- Azure Synapse Lakehouse Sync Pipelines

> NOTE: Two Synapse Dedicatd SQL Pools are created and running upon deployment. If you wish to pause the Dedicated SQL Pools to avoid charges, follow the steps [here](https://learn.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/pause-and-resume-compute-portal).

#### Azure Databricks Workspace
- Small Cluster
- Azure Synapse Lakehouse Sync Notebooks

#### Azure Data Lake Storage Gen2: Synapse Workspace
- **workspace:** Container for the Azure Synapse Analytics Workspace
- **synapsesync:** Container for Azure Synapse Lakehouse Sync change history from the Enterprise Data Lake Gold Zone. It also contains the **Synapse_Lakehouse_Sync_Metadata.csv** file which instructs Azure Synapse Lakehouse Sync on the tables that need to be synchronized.

#### Azure Data Lake Storage Gen2: Enterprise Data Lake
- **gold:** Container for the Enterprise Data Lake Gold Zone which includes the sample data

#### Azure Key Vault
- Secure storage for Azure Data Lake access keys and used by Databricks for authentication

# What's Configured
The **deployTutorial.sh** script will execute a Bicep deployment for the environment and then configure the environment with the Azure Synapse Lakehouse Sync artifacts including: 

- Synapse Workspace Pipelines
- Synapse Workspace Linked Services
- Synapse Workspace Datasets
- Synapse Dedicated SQL Pool
- Databricks Workspace Notebooks
- Databricks Workspace Cluster
- Azure Key Vault / Azure Data Lake Storage Access Keys
- Databricks Workspace / Azure Key Vault Secret Scope
- Sample Data
