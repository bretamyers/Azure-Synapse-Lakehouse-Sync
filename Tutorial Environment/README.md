# Azure Synapse Lakehouse Sync: Tutorial Environment

Whether you're new to the data lake & lakehouse pattern, or exploring how Synapse Lakehouse Sync would work in your environment, this will deploy an end-to-end tutorial environment. We wanted to provide an easy option for you to evaluate and understand how Azure Synapse Lakehouse Sync works with little effort.

<br>

# How to Deploy

The following commands should be executed from the Azure Cloud Shell at https://shell.azure.com using Bash. This will deploy the full tutorial environment with no additional configuration needed.

```
@Azure:~$ git clone https://github.com/bretamyers/Azure-Synapse-Lakehouse-Sync
@Azure:~$ cd 'Azure-Synapse-Lakehouse-Sync/Tutorial Environment'
@Azure:~$ bash deployTutorial.sh 
```

https://user-images.githubusercontent.com/16770830/192665633-1ecf047a-caae-44c8-b082-1580caee080c.mp4

<br>

# What's Deployed

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

<br>

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

<br>

# How to use Azure Synapse Lakehouse Sync Tutorial
After the deployment of the example environment through the Azure Cloud Shell has completed successfully, make note of the Synapse workspace name that was created and  navigate to the synapse workspace by going [web.azuresynapse.net](web.azuresynapse.net) and selecting the newly deployed workspace from the drop downs.

<img src="https://user-images.githubusercontent.com/14877390/192293164-3a99cef1-c0ae-448c-9d17-9dbbf408c496.png" width="600" />

Once in the Synapse workspace, navigate to the **Integrate** tab on the toolbar to the left and drill down to the **SynapseLakehouseSync_Tutorial** pipeline in the **Synapse Lakehouse Sync Tutorial** folder.

<img src="https://user-images.githubusercontent.com/14877390/192541566-7b4a0ffa-13f9-4bf3-8607-f175f514de7b.png" width="600" />
<img src="https://user-images.githubusercontent.com/14877390/192542004-d036d872-d2b7-4834-ac98-24af7e75a2b3.png" width="600" />

In the **SynapseLakehouseSync_Tutorial** pipeline, click on the **Add trigger** button in the top toolbar and select **Trigger now** and hit **OK** in the popup window. This will trigger the execution of the tutorial pipeline.

<img src="https://user-images.githubusercontent.com/14877390/192295875-d731ed9c-1ce1-43f8-8bc9-c187ca60448b.png" width="600" />
<img src="https://user-images.githubusercontent.com/14877390/192296498-197f406b-c144-4bfe-a848-2f2ac3cea9cc.png" width="400" />

<br>

# Azure Synapse Lakehouse Sync Tutorial Steps
The SynapeLakehouseSync_Tutorial pipeline is designed to simulate data loads that occur on the data in the gold zone on the data lake and sync those changes to the Synapse workspace dedicated pools. 
- First, we drop any existing tables from the Synapse dedicated pools if any exist. This step is there to allow consistent repeatability when rerunning the pipeline.
- Next we run an Azure Databricks notebook that converts the sample parquet dataset <b>AdventureWorks_parquet</b> provided in the deployment. This conversion does two primary things.
  - Creates a new table with change data feed enabled. A new Delta 2.0 functionality.
  - Adds an additional <b>_Id</b> column. This column is added with the Azure Databricks <b>GENERATED ALWAYS AS IDENTITY</b> feature. This piece is added to simplify and improve the performance of the sync process.
- Now that the parquet dataset has been converted to delta format with the change data feed feature enabled and the _Id column added, we then call the <b>SynapseLakehouseSync</b> pipeline to start the sync process. Since we drop any existing tables in the first step, this will trigger a full_load for all the tables. The <b>SynapseLakehouseSync</b> pipeline reads the provided sample metadata file <b>Synapse_Lakehouse_Sync_Metadata.csv</b>. This [metadata file](https://github.com/bretamyers/Azure-Synapse-Lakehouse-Sync/tree/main/Azure%20Synapse%20Lakehouse%20Sync#synaple-lakehouse-sync-metadata-file) contains the Synapse dedicated pool name, schema name, table name, key columns, delta table locations, and Synapse sync locations for each table to be sync'd. For the tutorial, we'll be loading into two separate Synapse dedicated pools demostrating that you can sync all the tables or a subset of the tables to different pools.
![image](https://user-images.githubusercontent.com/14877390/192312295-2f752a32-9f7c-4d89-8959-eae508e6d702.png)
- Once the full load of all the tables to the dedicated pool has completed, we then call an Azure Databricks notebook that simulates data changes to the underlying delta tables. The changes include update, inserts, deletes, and data type length changes. 
- We then execute the sync process by starting the <b>SynapseLakehouseSync</b> pipeline. Since the tables already exist in the Synapse dedicated pools, this triggers an incremental load which will execute separate insert, update, and delete statements to get the data in the Synapse dedicated pool up to date.
- Now that we've executed two Synapse sync's, we then call two lookup activities to check the row counts for each table querying the logging.SynapseLakehouseSync table that captures the row counts for the data in the delta tables and the row counts of the tables in the Synapse dedicated pools. The Diff column should be zero for all the tables.
- Now we pause the pipeline for 10 seconds using a wait activity.
- We execute the <b>SynapseLakehouseSync</b> pipeline for a third time. This execution will not load any new data to Synapse since no data changes have occurred on the delta tables. 
- Lastly, we run the two lookup activities again to verify that no data was loaded and that the row counts for the tables remain the same.
